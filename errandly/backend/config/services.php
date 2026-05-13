<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    */

    'mailgun' => [
        'domain'   => env('MAILGUN_DOMAIN'),
        'secret'   => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme'   => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key'    => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Paystack (Primary Nigerian Payment Gateway)
    | https://paystack.com/docs/api
    |--------------------------------------------------------------------------
    */
    'paystack' => [
        'public_key'     => env('PAYSTACK_PUBLIC_KEY'),
        'secret_key'     => env('PAYSTACK_SECRET_KEY'),
        'webhook_secret' => env('PAYSTACK_WEBHOOK_SECRET'),
        'base_url'       => 'https://api.paystack.co',
    ],

    /*
    |--------------------------------------------------------------------------
    | Flutterwave (Secondary Nigerian Payment Gateway)
    | https://developer.flutterwave.com/docs
    |--------------------------------------------------------------------------
    */
    'flutterwave' => [
        'public_key'     => env('FLUTTERWAVE_PUBLIC_KEY'),
        'secret_key'     => env('FLUTTERWAVE_SECRET_KEY'),
        'encryption_key' => env('FLUTTERWAVE_ENCRYPTION_KEY'),
        'webhook_secret' => env('FLUTTERWAVE_WEBHOOK_SECRET'),
        'base_url'       => 'https://api.flutterwave.com/v3',
    ],

    /*
    |--------------------------------------------------------------------------
    | Stripe (International Cards)
    | https://stripe.com/docs/api
    |--------------------------------------------------------------------------
    */
    'stripe' => [
        'key'            => env('STRIPE_PUBLIC_KEY'),
        'secret'         => env('STRIPE_SECRET_KEY'),
        'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Termii (SMS OTP — Nigeria)
    | https://developers.termii.com
    |--------------------------------------------------------------------------
    */
    'termii' => [
        'api_key'  => env('TERMII_API_KEY'),
        'base_url' => 'https://api.ng.termii.com/api',
        'sender_id' => env('TERMII_SENDER_ID', 'Errandly'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Google Maps (Geocoding + Distance Matrix)
    |--------------------------------------------------------------------------
    */
    'google_maps' => [
        'api_key' => env('GOOGLE_MAPS_API_KEY'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Firebase (Push Notifications)
    |--------------------------------------------------------------------------
    */
    'firebase' => [
        'credentials_file' => env('FIREBASE_CREDENTIALS'),
        'project_id'       => env('FIREBASE_PROJECT_ID'),
    ],

];
