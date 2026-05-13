<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            // Errand permissions
            'errand.create', 'errand.view', 'errand.cancel', 'errand.assign', 'errand.reassign',
            // User permissions
            'user.view', 'user.suspend', 'user.blacklist', 'user.restore', 'user.delete',
            // KYC permissions
            'kyc.view', 'kyc.approve', 'kyc.reject',
            // Finance permissions
            'finance.view', 'finance.refund', 'finance.release', 'finance.freeze',
            // Dispute permissions
            'dispute.view', 'dispute.resolve', 'dispute.assign',
            // Runner permissions
            'runner.approve', 'runner.suspend', 'runner.trust-score.adjust',
            // Report permissions
            'report.view', 'report.export',
            // Settings permissions
            'settings.view', 'settings.update',
            // Notification permissions
            'notification.broadcast',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        // Roles
        $customer = Role::firstOrCreate(['name' => 'customer']);
        $runner = Role::firstOrCreate(['name' => 'runner']);
        $admin = Role::firstOrCreate(['name' => 'admin']);
        $verificationOfficer = Role::firstOrCreate(['name' => 'verification_officer']);
        $superAdmin = Role::firstOrCreate(['name' => 'super_admin']);

        $customer->syncPermissions(['errand.create', 'errand.view', 'errand.cancel']);
        $runner->syncPermissions(['errand.view']);
        $verificationOfficer->syncPermissions(['kyc.view', 'kyc.approve', 'kyc.reject', 'user.view']);
        $admin->syncPermissions(Permission::all());
        $superAdmin->syncPermissions(Permission::all());
    }
}
