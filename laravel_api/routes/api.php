<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\PlaceController;
use App\Http\Controllers\SocialAuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Rutas públicas (no requieren token)
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

// Recuperación de contraseña
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password',  [AuthController::class, 'resetPassword']);

// Rutas para Google Login
Route::get('/auth/google',          [SocialAuthController::class, 'redirectToGoogle']);
Route::get('/auth/google/callback', [SocialAuthController::class, 'handleGoogleCallback']);
Route::post('/auth/google/flutter', [SocialAuthController::class, 'handleGoogleToken']);

// Ruta pública para obtener el usuario autenticado
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Rutas protegidas con Sanctum
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/places',            [PlaceController::class, 'index']);
    Route::post('/places',           [PlaceController::class, 'store']);
    Route::get('/places/{place}',    [PlaceController::class, 'show']);
    Route::put('/places/{place}',    [PlaceController::class, 'update']);
    Route::post('/places/{place}',   [PlaceController::class, 'update']); // Para multipart con imagen
    Route::delete('/places/{place}', [PlaceController::class, 'destroy']);
});