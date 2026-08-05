<?php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthStagiaireController;
use App\Http\Controllers\AuthEntrepriseController;
use App\Http\Controllers\ReferentielController;
use App\Http\Controllers\CarnetController;
use App\Http\Controllers\FicheStagiaireInviteController;
use App\Http\Controllers\RattachementController;
use App\Http\Controllers\PointageController;
use App\Http\Controllers\EvaluationController;
use App\Http\Controllers\DocumentController;
use App\Http\Controllers\TrajetController;
use App\Http\Controllers\ReservationController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\SignalementController;
use App\Http\Controllers\CritereSavoirEtreController;
use App\Http\Controllers\EvaluationSavoirEtreController;
use App\Http\Controllers\BilanReflexifController;

Route::prefix('auth/stagiaire')->group(function () {
    Route::post('demander-code', [AuthStagiaireController::class, 'demanderCode']);
    Route::post('verifier-code', [AuthStagiaireController::class, 'verifierCode']);
});

Route::prefix('auth/entreprise')->group(function () {
    Route::post('demander-code', [AuthEntrepriseController::class, 'demanderCode']);
    Route::post('verifier-code', [AuthEntrepriseController::class, 'verifierCode']);
});
Route::middleware('auth:sanctum')->get('/profil/moi', function (Request $request) {
    return response()->json([
        'id' => $request->user()->id,
        'email' => $request->user()->email,
        'type' => get_class($request->user()), // pour voir si c'est un Stagiaire ou une Entreprise
    ]);
});
Route::middleware(['auth:sanctum', 'profil:entreprise'])->get('/profil/reserve-entreprise', function (Request $request) {
    return response()->json(['message' => "Bienvenue, entreprise {$request->user()->email}"]);
});


// Référentiel — public, pas besoin d'être connecté
Route::prefix('referentiel')->group(function () {
    Route::get('domaines', [ReferentielController::class, 'domaines']);
    Route::get('metiers', [ReferentielController::class, 'metiers']);
    Route::get('niveaux-formation', [ReferentielController::class, 'niveauxFormation']);
    Route::get('competences', [ReferentielController::class, 'competences']);
});

// Carnet — réservé aux stagiaires connectés
Route::middleware(['auth:sanctum', 'profil:stagiaire'])->prefix('carnets')->group(function () {
    Route::post('/', [CarnetController::class, 'store']);
    Route::get('/', [CarnetController::class, 'index']);
});


// Réservé aux entreprises
Route::middleware(['auth:sanctum', 'profil:entreprise'])->prefix('fiches-invitation')->group(function () {
    Route::post('/', [FicheStagiaireInviteController::class, 'store']);
    Route::get('/', [FicheStagiaireInviteController::class, 'index']);
});

// Réservé aux stagiaires
Route::middleware(['auth:sanctum', 'profil:stagiaire'])->post('/rattacher-carnet', [RattachementController::class, 'rattacher']);



Route::middleware(['auth:sanctum', 'profil:stagiaire'])->prefix('pointage')->group(function () {
    Route::post('arrivee', [PointageController::class, 'arrivee']);
    Route::post('depart', [PointageController::class, 'depart']);
    Route::get('{carnetId}/historique', [PointageController::class, 'historique']);
});


// Réservé aux entreprises
Route::middleware(['auth:sanctum', 'profil:entreprise'])->group(function () {
    Route::post('/evaluations', [EvaluationController::class, 'store']);
    Route::get('/carnets/{carnetId}/evaluations', [EvaluationController::class, 'index']);

    Route::post('/evaluations/{evaluationId}/attestation', [DocumentController::class, 'genererAttestation']);
    Route::post('/evaluations/{evaluationId}/carte-appui', [DocumentController::class, 'genererCarteAppui']);
});

// Réservé aux stagiaires
Route::middleware(['auth:sanctum', 'profil:stagiaire'])->get('/mes-attestations', [DocumentController::class, 'mesAttestations']);


Route::middleware(['auth:sanctum', 'profil:stagiaire'])->group(function () {
    // Trajets
    Route::post('/trajets', [TrajetController::class, 'store']);
    Route::get('/trajets', [TrajetController::class, 'index']);
    Route::get('/mes-trajets', [TrajetController::class, 'mesTrajets']);

    // Réservations
    Route::post('/trajets/{trajetId}/reserver', [ReservationController::class, 'store']);
    Route::post('/reservations/{reservationId}/annuler', [ReservationController::class, 'annuler']);
    Route::get('/mes-reservations', [ReservationController::class, 'mesReservations']);

    // Messagerie
    Route::post('/trajets/{trajetId}/messages', [MessageController::class, 'store']);
    Route::get('/trajets/{trajetId}/messages', [MessageController::class, 'index']);

    // Signalement
    Route::post('/trajets/{trajetId}/signaler', [SignalementController::class, 'store']);
});


// Critères — accessibles aux deux profils connectés
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/criteres-savoir-etre', [CritereSavoirEtreController::class, 'index']);
});

// Réservé aux entreprises — savoir-être JAMAIS exposé au stagiaire
Route::middleware(['auth:sanctum', 'profil:entreprise'])->group(function () {
    Route::post('/criteres-savoir-etre', [CritereSavoirEtreController::class, 'store']);
    Route::post('/evaluations-savoir-etre', [EvaluationSavoirEtreController::class, 'store']);
    Route::get('/carnets/{carnetId}/evaluations-savoir-etre', [EvaluationSavoirEtreController::class, 'index']);
});

// Réservé aux stagiaires — bilan réflexif JAMAIS exposé au tuteur
Route::middleware(['auth:sanctum', 'profil:stagiaire'])->group(function () {
    Route::post('/bilans-reflexifs', [BilanReflexifController::class, 'store']);
    Route::get('/carnets/{carnetId}/bilans-reflexifs', [BilanReflexifController::class, 'index']);
});