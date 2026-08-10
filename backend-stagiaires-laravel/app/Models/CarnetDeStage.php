<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class CarnetDeStage extends Model
{
    use HasFactory, HasUuids;

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
        'date_creation',
    ];

    protected $casts = [
        'autorisation_suivi' => 'boolean',
        'date_debut' => 'date',
        'date_fin' => 'date',
        'date_rattachement' => 'datetime',
        'date_creation' => 'datetime',
    ];

    public function stagiaire()
    {
        return $this->belongsTo(Stagiaire::class);
    }

    public function entreprise()
    {
        return $this->belongsTo(Entreprise::class);
    }

    public function domaineFormation()
    {
        return $this->belongsTo(DomaineFormation::class);
    }

    public function metier()
    {
        return $this->belongsTo(Metier::class);
    }

    public function niveauFormation()
    {
        return $this->belongsTo(NiveauFormation::class);
    }

    public function entrees()
    {
        return $this->hasMany(EntreeCarnet::class);
    }

    public function progressions()
    {
        return $this->hasMany(ProgressionCompetence::class);
    }

    public function indicateurAssiduite()
    {
        return $this->hasOne(IndicateurAssiduite::class);
    }

    public function estRattache()
    {
        return $this->entreprise_id !== null;
    }

    public function estEnCours()
    {
        return $this->statut === 'EN_COURS';
    }
}
