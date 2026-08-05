<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class CarnetDeStage extends Model
{
    use HasUuids;

    protected $table = 'carnets_de_stage';

    public $timestamps = false; // notre table n'a pas created_at/updated_at, juste date_creation

    protected $fillable = [
        'stagiaire_id',
        'entreprise_id',
        'domaine_formation_id',
        'metier_id',
        'niveau_formation_id',
        'statut',
        'code_rattachement_utilise',
        'date_rattachement',
        'autorisation_suivi',
        'date_debut',
        'date_fin',
    ];

    protected $casts = [
        'autorisation_suivi' => 'boolean',
        'date_rattachement' => 'datetime',
        'date_debut' => 'date',
        'date_fin' => 'date',
    ];

    // Relation inverse : un carnet appartient à un seul stagiaire
    public function stagiaire()
    {
        return $this->belongsTo(Stagiaire::class, 'stagiaire_id');
    }

    // Un carnet appartient (optionnellement) à une entreprise
    public function entreprise()
    {
        return $this->belongsTo(Entreprise::class, 'entreprise_id');
    }
}