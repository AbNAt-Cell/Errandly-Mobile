<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    /**
     * Upload a file (image, PDF document, proof) to persistent storage.
     */
    public function upload(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|file|mimes:jpeg,png,jpg,gif,webp,pdf|max:10240',
            'folder' => 'nullable|string|in:kyc,proofs,avatars,disputes,general',
        ]);

        $folder = $request->input('folder', 'general');
        $file = $request->file('file');

        $disk = config('filesystems.default', 'public');
        $filename = Str::random(24) . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs("uploads/{$folder}", $filename, $disk);

        $url = Storage::disk($disk)->url($path);

        return response()->json([
            'message' => 'File uploaded successfully',
            'url' => $url,
            'path' => $path,
        ]);
    }
}
