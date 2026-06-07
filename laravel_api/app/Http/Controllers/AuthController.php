<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache;

class AuthController extends Controller
{
    // POST /api/register
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'apellido' => 'required|string|max:255',
            'nivel_educativo'  => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
                'regex:/^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[\W_]).+$/',
            ],
        ], [
            'password.min'       => 'La contraseña debe tener mínimo 8 caracteres.',
            'password.regex'     => 'La contraseña debe tener letras, números y un símbolo.',
            'password.confirmed' => 'Las contraseñas no coinciden.',
            'email.unique'       => 'Este correo ya está registrado.',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'apellido' => $validated['apellido'],
            'nivel_educativo' => $validated['nivel_educativo'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user'  => $user,
            'token' => $token,
        ], 201);
    }

    // POST /api/login
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'error_type' => 'email',
                'message'    => 'Este correo no está registrado.',
            ], 401);
        }

        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'error_type' => 'password',
                'message'    => 'Contraseña incorrecta.',
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user'  => $user,
            'token' => $token,
        ]);
    }

    // POST /api/logout
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Sesión cerrada correctamente']);
    }

    // POST /api/forgot-password — genera un código de 6 dígitos
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'message' => 'No existe una cuenta con este correo.',
            ], 404);
        }

        // Generar código de 6 dígitos y guardarlo en cache por 10 minutos
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        Cache::put('password_reset_' . $request->email, $code, now()->addMinutes(10));

        // En producción aquí enviarías el código por email
        // Para desarrollo, lo retornamos en la respuesta
        return response()->json([
            'message' => 'Código de recuperación generado.',
            'code'    => $code, // En producción remover esta línea
        ]);
    }

    // POST /api/reset-password — verifica código y cambia contraseña
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'code'     => 'required|string|size:6',
            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
            ],
        ]);

        $cachedCode = Cache::get('password_reset_' . $request->email);

        if (!$cachedCode || $cachedCode !== $request->code) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], 422);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'message' => 'No existe una cuenta con este correo.',
            ], 404);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        // Eliminar código usado
        Cache::forget('password_reset_' . $request->email);

        // Revocar todos los tokens anteriores
        $user->tokens()->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Contraseña actualizada correctamente.',
            'user'    => $user,
            'token'   => $token,
        ]);
    }
}