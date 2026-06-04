<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Place extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'description',
        'latitude',
        'longitude',
        'image',
    ];

    protected $casts = [
        'latitude'  => 'float',
        'longitude' => 'float',
    ];

    // Un place pertenece a un usuario
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}