<?php

namespace App\Http\Controllers;

use App\Models\Place;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PlaceController extends Controller
{
    // GET /api/places — listar los places del usuario autenticado
    public function index(Request $request)
    {
        $places = $request->user()->places()->latest()->get();

        // Agregar URL completa de la imagen
        $places->transform(function ($place) use ($request) {
            if ($place->image) {
                $place->image_url = $request->getSchemeAndHttpHost() . '/storage/' . $place->image;
            } else {
                $place->image_url = null;
            }
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

        // Manejar subida de imagen
        if ($request->hasFile('image')) {
            $validated['image'] = $request->file('image')->store('places', 'public');
        }

        $place = $request->user()->places()->create($validated);

        // Agregar URL completa
        if ($place->image) {
            $place->image_url = $request->getSchemeAndHttpHost() . '/storage/' . $place->image;
        } else {
            $place->image_url = null;
        }

        return response()->json($place, 201);
    }

    // GET /api/places/{id} — ver un place específico
    public function show(Request $request, Place $place)
    {
        if ($place->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        if ($place->image) {
            $place->image_url = $request->getSchemeAndHttpHost() . '/storage/' . $place->image;
        } else {
            $place->image_url = null;
        }

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

        // Manejar subida de nueva imagen
        if ($request->hasFile('image')) {
            // Eliminar imagen anterior si existe
            if ($place->image) {
                Storage::disk('public')->delete($place->image);
            }
            $validated['image'] = $request->file('image')->store('places', 'public');
        }

        $place->update($validated);

        if ($place->image) {
            $place->image_url = $request->getSchemeAndHttpHost() . '/storage/' . $place->image;
        } else {
            $place->image_url = null;
        }

        return response()->json($place, 200);
    }

    // DELETE /api/places/{id} — eliminar un place
    public function destroy(Request $request, Place $place)
    {
        if ($place->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        // Eliminar imagen si existe
        if ($place->image) {
            Storage::disk('public')->delete($place->image);
        }

        $place->delete();

        return response()->json(['message' => 'Place deleted'], 200);
    }
}