<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AdminSettingsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $settings = DB::table('settings')->get()->keyBy('key');
        return response()->json($settings);
    }

    public function update(Request $request): JsonResponse
    {
        foreach ($request->all() as $key => $value) {
            DB::table('settings')->updateOrInsert(
                ['key' => $key],
                ['value' => $value, 'updated_at' => now()]
            );
        }

        return response()->json(['message' => 'Settings updated.']);
    }

    public function serviceAreas(Request $request): JsonResponse
    {
        $areas = DB::table('service_areas')->get();
        return response()->json($areas);
    }

    public function storeServiceArea(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string',
            'city' => 'required|string',
            'state' => 'required|string',
            'center_latitude' => 'required|numeric',
            'center_longitude' => 'required|numeric',
            'radius_km' => 'required|integer|min:1',
        ]);

        $id = DB::table('service_areas')->insertGetId(array_merge(
            $request->only('name', 'city', 'state', 'center_latitude', 'center_longitude', 'radius_km'),
            ['is_active' => true, 'created_at' => now(), 'updated_at' => now()]
        ));

        return response()->json(['message' => 'Service area created.', 'id' => $id], 201);
    }

    public function updateServiceArea(Request $request, int $id): JsonResponse
    {
        DB::table('service_areas')->where('id', $id)->update(array_merge(
            $request->only('name', 'city', 'state', 'center_latitude', 'center_longitude', 'radius_km', 'is_active'),
            ['updated_at' => now()]
        ));

        return response()->json(['message' => 'Service area updated.']);
    }

    public function deleteServiceArea(Request $request, int $id): JsonResponse
    {
        DB::table('service_areas')->where('id', $id)->delete();
        return response()->json(['message' => 'Service area deleted.']);
    }
}
