<?php

namespace App\Http\Controllers;

use App\Models\Place;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class PlaceController extends Controller
{
    // ── Sube imagen a ImgBB y devuelve la URL ──────────
    private function subirImagenImgBB($archivo): ?string
    {
        $response = Http::post('https://api.imgbb.com/1/upload', [
            'key'   => '02d4e6525eeb97542a9b5f9a5a4227e6',
            'image' => base64_encode(file_get_contents($archivo->getRealPath())),
            'name'  => $archivo->getClientOriginalName(),
        ]);

        if ($response->successful()) {
            return $response->json('data.url'); // URL directa de la imagen
        }

        return null;
    }

    // GET /api/places — listar los places del usuario autenticado
    public function index(Request $request)
    {
        $places = $request->user()->places()->latest()->get();

        $places->transform(function ($place) {
            // image ahora guarda directamente la URL de ImgBB
            $place->image_url = $place->image ?? null;
            return $place;
        });

        return response()->json($places);
    }

    // POST /api/places — crear un nuevo place (con imagen opcional)
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'description' => 'nullable|string',
            'latitude'    => 'required|numeric|between:-90,90',
            'longitude'   => 'required|numeric|between:-180,180',
            'image'       => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        // Subir imagen a ImgBB si existe
        if ($request->hasFile('image')) {
            $url = $this->subirImagenImgBB($request->file('image'));
            $validated['image'] = $url; // guardamos la URL directa
        }

        $place = $request->user()->places()->create($validated);
        $place->image_url = $place->image ?? null;

        return response()->json($place, 201);
    }

    // GET /api/places/{id} — ver un place específico
    public function show(Request $request, Place $place)
    {
        if ($place->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $place->image_url = $place->image ?? null;

        return response()->json($place);
    }

    // PUT/POST /api/places/{id} — actualizar un place
    public function update(Request $request, Place $place)
    {
        if ($place->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'description' => 'nullable|string',
            'latitude'    => 'required|numeric|between:-90,90',
            'longitude'   => 'required|numeric|between:-180,180',
            'image'       => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        // Subir nueva imagen a ImgBB si existe
        if ($request->hasFile('image')) {
            $url = $this->subirImagenImgBB($request->file('image'));
            if ($url) {
                $validated['image'] = $url;
            }
        }

        $place->update($validated);
        $place->image_url = $place->image ?? null;

        return response()->json($place, 200);
    }

    // DELETE /api/places/{id} — eliminar un place
    public function destroy(Request $request, Place $place)
    {
        if ($place->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        // ImgBB no tiene API para eliminar en plan gratuito,
        // solo eliminamos el registro de la base de datos
        $place->delete();

        return response()->json(['message' => 'Place deleted'], 200);
    }
}