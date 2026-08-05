<?php
 
namespace App\Models;
 
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Laravel\Sanctum\HasApiTokens;
 
class Entreprise extends Model
{
    use HasUuids, HasApiTokens;
 
    protected $table = 'entreprises';
    public $timestamps = false;
 
    protected $fillable = [
        'email', 'raison_sociale', 'secteur',
        'adresse_libelle', 'adresse_lat', 'adresse_lng',
        'rayon_detection_metres', 'heure_debut_journee', 'heure_fin_journee',
        'pause_heure_debut', 'pause_heure_fin', 'derniere_connexion',
    ];
 
    protected $casts = [
        'derniere_connexion' => 'datetime',
    ];
 
    public function carnetsDeStage()
    {
        return $this->hasMany(CarnetDeStage::class, 'entreprise_id');
    }
 
    public function fichesStagiaireInvite()
    {
        return $this->hasMany(FicheStagiaireInvite::class, 'entreprise_id');
    }
 
    public function competencesAjoutees()
    {
        return $this->hasMany(Competence::class, 'entreprise_id');
    }
 
    public function criteresSavoirEtreAjoutes()
    {
        return $this->hasMany(CritereSavoirEtre::class, 'entreprise_id');
    }
}