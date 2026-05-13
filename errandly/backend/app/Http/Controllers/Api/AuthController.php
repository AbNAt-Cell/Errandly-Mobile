<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\RunnerProfile;
use App\Services\WalletService;
use App\Services\OtpService;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function __construct(
        private WalletService $walletService,
        private OtpService $otpService,
        private NotificationService $notificationService,
    ) {}

    public function registerCustomer(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'phone' => 'required|string|unique:users,phone',
            'password' => ['required', Password::min(8)->mixedCase()->numbers()],
            'referral_code' => 'nullable|string|exists:users,referral_code',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = DB::transaction(function () use ($request) {
            $referrer = null;
            if ($request->referral_code) {
                $referrer = User::where('referral_code', $request->referral_code)->first();
            }

            $user = User::create([
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'email' => $request->email,
                'phone' => $request->phone,
                'password' => Hash::make($request->password),
                'referral_code' => $this->generateReferralCode(),
                'referred_by' => $referrer?->id,
                'status' => User::STATUS_ACTIVE,
                'kyc_status' => User::KYC_PENDING,
            ]);

            $user->assignRole('customer');
            $this->walletService->createWalletForUser($user);

            // Send phone OTP for verification
            $otp = $this->otpService->generateAuthOtp($user->phone);
            // In production: send via Twilio SMS

            return $user;
        });

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful. Please verify your phone number.',
            'user' => $this->formatUser($user),
            'token' => $token,
        ], 201);
    }

    public function registerRunner(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'phone' => 'required|string|unique:users,phone',
            'password' => ['required', Password::min(8)->mixedCase()->numbers()],
            'city' => 'required|string',
            'state' => 'required|string',
            'transport_type' => 'required|in:foot,bicycle,motorcycle,car',
            'service_radius_km' => 'nullable|integer|min:1|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = DB::transaction(function () use ($request) {
            $user = User::create([
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'email' => $request->email,
                'phone' => $request->phone,
                'password' => Hash::make($request->password),
                'city' => $request->city,
                'state' => $request->state,
                'referral_code' => $this->generateReferralCode(),
                'status' => User::STATUS_PENDING,
                'kyc_status' => User::KYC_PENDING,
            ]);

            $user->assignRole('runner');

            RunnerProfile::create([
                'user_id' => $user->id,
                'transport_type' => $request->transport_type,
                'service_radius_km' => $request->service_radius_km ?? 10,
                'service_city' => $request->city,
                'service_state' => $request->state,
                'verification_status' => RunnerProfile::VERIFICATION_PENDING,
                'trust_score' => 70,
                'completion_rate' => 100,
                'is_online' => false,
                'is_available' => false,
            ]);

            $this->walletService->createWalletForUser($user);

            return $user;
        });

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Runner registration submitted. Please complete your verification.',
            'user' => $this->formatUser($user),
            'token' => $token,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'login' => 'required|string',
            'password' => 'required|string',
            'device_token' => 'nullable|string',
            'device_type' => 'nullable|in:ios,android,web',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::where('email', $request->login)
            ->orWhere('phone', $request->login)
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        if ($user->status === User::STATUS_BLACKLISTED) {
            return response()->json(['message' => 'Your account has been permanently suspended.'], 403);
        }

        if ($user->status === User::STATUS_SUSPENDED) {
            return response()->json([
                'message' => 'Your account is suspended.',
                'suspension_reason' => $user->suspension_reason,
                'suspended_until' => $user->suspended_until,
            ], 403);
        }

        // Update device token if provided
        if ($request->device_token) {
            $user->update([
                'device_token' => $request->device_token,
                'device_type' => $request->device_type ?? 'web',
            ]);
        }

        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $this->formatUser($user->load(['runnerProfile', 'wallet'])),
            'token' => $token,
            'roles' => $user->getRoleNames(),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load(['runnerProfile', 'wallet', 'kyc']);
        return response()->json([
            'user' => $this->formatUser($user),
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'sometimes|string|max:100',
            'last_name' => 'sometimes|string|max:100',
            'address' => 'sometimes|string',
            'city' => 'sometimes|string',
            'state' => 'sometimes|string',
            'emergency_contact_name' => 'sometimes|string',
            'emergency_contact_phone' => 'sometimes|string',
            'date_of_birth' => 'sometimes|date',
            'gender' => 'sometimes|in:male,female,other',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $request->user()->update($validator->validated());

        return response()->json([
            'message' => 'Profile updated.',
            'user' => $this->formatUser($request->user()),
        ]);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'password' => ['required', Password::min(8)->mixedCase()->numbers(), 'confirmed'],
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if (!Hash::check($request->current_password, $request->user()->password)) {
            return response()->json(['message' => 'Current password is incorrect.'], 400);
        }

        $request->user()->update(['password' => Hash::make($request->password)]);
        $request->user()->tokens()->delete();

        return response()->json(['message' => 'Password changed. Please login again.']);
    }

    public function verifyPhone(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string',
            'otp' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if (!$this->otpService->verifyAuthOtp($request->phone, $request->otp)) {
            return response()->json(['message' => 'Invalid or expired OTP.'], 400);
        }

        $user = User::where('phone', $request->phone)->firstOrFail();
        $user->update(['phone_verified_at' => now()]);

        return response()->json(['message' => 'Phone verified successfully.']);
    }

    public function resendOtp(Request $request): JsonResponse
    {
        $user = $request->user();
        $otp = $this->otpService->generateAuthOtp($user->phone);
        // Send via Twilio in production

        return response()->json(['message' => 'OTP sent to your phone.']);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Send password reset email
        \Illuminate\Support\Facades\Password::sendResetLink($request->only('email'));

        return response()->json(['message' => 'Password reset link sent to your email.']);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'token' => 'required|string',
            'email' => 'required|email',
            'password' => ['required', Password::min(8)->mixedCase()->numbers(), 'confirmed'],
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $status = \Illuminate\Support\Facades\Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->update(['password' => Hash::make($password)]);
                $user->tokens()->delete();
            }
        );

        return $status === \Illuminate\Support\Facades\Password::PASSWORD_RESET
            ? response()->json(['message' => 'Password reset successfully.'])
            : response()->json(['message' => 'Invalid reset token.'], 400);
    }

    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json(['token' => $token]);
    }

    public function updateDeviceToken(Request $request): JsonResponse
    {
        $request->validate(['device_token' => 'required|string', 'device_type' => 'nullable|in:ios,android,web']);
        $request->user()->update(['device_token' => $request->device_token, 'device_type' => $request->device_type]);
        return response()->json(['message' => 'Device token updated.']);
    }

    private function generateReferralCode(): string
    {
        do {
            $code = strtoupper(\Illuminate\Support\Str::random(8));
        } while (User::where('referral_code', $code)->exists());

        return $code;
    }

    private function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'full_name' => $user->full_name,
            'email' => $user->email,
            'phone' => $user->phone,
            'profile_image' => $user->profile_image,
            'status' => $user->status,
            'kyc_status' => $user->kyc_status,
            'phone_verified_at' => $user->phone_verified_at,
            'email_verified_at' => $user->email_verified_at,
            'referral_code' => $user->referral_code,
            'city' => $user->city,
            'state' => $user->state,
            'is_online' => $user->is_online,
            'runner_profile' => $user->relationLoaded('runnerProfile') ? $user->runnerProfile : null,
            'wallet_balance' => $user->relationLoaded('wallet') ? $user->wallet?->balance : null,
        ];
    }
}
