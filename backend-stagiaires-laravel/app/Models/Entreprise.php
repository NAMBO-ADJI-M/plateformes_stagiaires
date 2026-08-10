<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class Entreprise extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'email',
        'raison_sociale',
        'secteur',
        'adresse_libelle',
        'adresse_lat',
        'adresse_lng',
        'rayon_detection_metres',
        'heure_debut_journee',
        'heure_fin_journee',
        'pause_heure_debut',
        'pause_heure_fin',
        'profil_complet',
        'telephone',
        'site_web',
        'derniere_connexion',
    ];

    protected $casts = [
        'profil_complet' => 'boolean',
        'rayon_detection_metres' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function stagiaires()
    {
        return $this->hasMany(Stagiaire::class);
    }

    public function carnets()
    {
        return $this->hasMany(CarnetDeStage::class);
    }

    public function cartesAppui()
    {
        return $this->hasMany(CarteAppuiStage::class, 'entreprise_emettrice_id');
    }

    public function invitations()
    {
        return $this->hasMany(FicheStagiaireInvite::class);
    }

    public function isComplete()
    {
        return $this->profil_complet;
    }
}
