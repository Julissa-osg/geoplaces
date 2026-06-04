<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Laravel\Socialite\Facades\Socialite;

class SocialAuthController extends Controller
{
    // Redirige a Google (para web browser)
    public function redirectToGoogle()
    {
        return Socialite::driver('google')->stateless()->redirect();
    }

    // Google regresa aquí (para web browser)
    public function handleGoogleCallback()
    {
        try {
            $googleUser = Socialite::driver('google')->stateless()->user();

            $user = User::updateOrCreate(
                ['email' => $googleUser->getEmail()],
                [
                    'name'      => $googleUser->getName(),
                    'google_id' => $googleUser->getId(),
                    'password'  => bcrypt(uniqid()),
                ]
            );

            $token = $user->createToken('auth_token')->plainTextToken;
            return redirect('http://localhost:65002/#/google-callback?token=' . $token);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    // ✅ Recibe el token de Google desde Flutter Web
    public function handleGoogleToken(Request $request)
    {
        try {
            $idToken = $request->input('id_token');
            if (!$idToken) {
                return response()->json(['error' => 'Token requerido'], 422);
            }

            // Verifica el token con Google
            $googleUser = Socialite::driver('google')->stateless()->userFromToken($idToken);

            $user = User::updateOrCreate(
                ['email' => $googleUser->getEmail()],
                [
                    'name'      => $googleUser->getName(),
                    'google_id' => $googleUser->getId(),
                    'password'  => bcrypt(uniqid()),
                ]
            );

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'user'  => $user,
                'token' => $token,
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}