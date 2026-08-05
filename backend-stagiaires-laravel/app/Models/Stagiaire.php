<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Laravel\Sanctum\HasApiTokens;

class Stagiaire extends Model
{
    use HasUuids, HasApiTokens;

    protected $table = 'stagiaires';

    protected $fillable = [
        'email',
        'nom',
        'prenom',
        'photo_profil',
        'domicile_adresse',
        'domicile_lat',
        'domicile_lng',
        'autorisation_entraide',
        'date_premiere_connexion',
        'derniere_connexion',
    ];

    protected $casts = [
        'autorisation_entraide' => 'boolean',
        'date_premiere_connexion' => 'datetime',
        'derniere_connexion' => 'datetime',
    ];

    // Relation 1,N : un stagiaire possède plusieurs carnets de stage
    public function carnetsDeStage()
    {
        return $this->hasMany(CarnetDeStage::class, 'stagiaire_id');
    }
}