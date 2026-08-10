<?php

namespace App\Models;

<<<<<<< HEAD
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;


class Stagiaire extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
=======
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Laravel\Sanctum\HasApiTokens;

class Stagiaire extends Model
{
    use HasUuids, HasApiTokens;

    protected $table = 'stagiaires';

    protected $fillable = [
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
        'email',
        'nom',
        'prenom',
        'photo_profil',
        'domicile_adresse',
        'domicile_lat',
        'domicile_lng',
        'autorisation_entraide',
<<<<<<< HEAD
        'profil_complet',
        'carnet_creer',
        'date_naissance',
        'telephone',
        'ecole',
        'filiere',
        'niveau',
=======
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
        'date_premiere_connexion',
        'derniere_connexion',
    ];

    protected $casts = [
        'autorisation_entraide' => 'boolean',
<<<<<<< HEAD
        'profil_complet' => 'boolean',
        'carnet_creer' => 'boolean',
        'date_naissance' => 'date',
=======
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
        'date_premiere_connexion' => 'datetime',
        'derniere_connexion' => 'datetime',
    ];

<<<<<<< HEAD
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function carnets()
    {
        return $this->hasMany(CarnetDeStage::class);
    }

    public function trajets()
    {
        return $this->hasMany(Trajet::class, 'conducteur_id');
    }

    public function reservations()
    {
        return $this->hasMany(Reservation::class, 'passager_id');
    }

    public function messages()
    {
        return $this->hasMany(Message::class, 'auteur_id');
    }

    public function signalements()
    {
        return $this->hasMany(Signalement::class, 'auteur_id');
    }

    public function getFullNameAttribute()
    {
        return $this->prenom . ' ' . $this->nom;
    }

    public function isComplete()
    {
        return $this->profil_complet && $this->carnet_creer;
    }
}
=======
    // Relation 1,N : un stagiaire possède plusieurs carnets de stage
    public function carnetsDeStage()
    {
        return $this->hasMany(CarnetDeStage::class, 'stagiaire_id');
    }
}
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
