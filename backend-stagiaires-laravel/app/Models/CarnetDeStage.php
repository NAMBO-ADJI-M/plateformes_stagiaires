<?php

namespace App\Models;

<<<<<<< HEAD
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class CarnetDeStage extends Model
{
    use HasFactory, HasUuids;
=======
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class CarnetDeStage extends Model
{
    use HasUuids;

    protected $table = 'carnets_de_stage';

    public $timestamps = false; // notre table n'a pas created_at/updated_at, juste date_creation
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e

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
<<<<<<< HEAD
        'date_creation',
=======
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
    ];

    protected $casts = [
        'autorisation_suivi' => 'boolean',
<<<<<<< HEAD
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
=======
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
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
