<?php
<<<<<<< HEAD

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Auth\AuthController;
=======
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthStagiaireController;
use App\Http\Controllers\AuthEntrepriseController;
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
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
<<<<<<< HEAD
use App\Http\Controllers\TestEmailController; // ✅ AJOUTER CET IMPORT

// ================================================
// 🔐 ROUTE LOGIN POUR SANCTUM (ÉVITE L'ERREUR)
// ================================================
Route::get('/login', function () {
    return response()->json([
        'message' => 'Non authentifié. Veuillez vous connecter.'
    ], 401);
})->name('login');

// ================================================
// 📧 ROUTE DE TEST EMAIL
// ================================================
Route::get('/test-email', [TestEmailController::class, 'sendTestEmail']);

// ================================================
// AUTHENTIFICATION UNIFIÉE - PUBLIC
// ================================================
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('verify', [AuthController::class, 'verify']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('resend-code', [AuthController::class, 'resendCode']);
});

// ================================================
// ROUTES PROTÉGÉES (AUTH + PROFIL)
// ================================================
Route::middleware('auth:sanctum')->group(function () {
    
    // Auth
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::get('auth/profile', [AuthController::class, 'profile']);
    
    // ============================================
    // PROFIL - Complétion
    // ============================================
    Route::middleware('profil:stagiaire')->group(function () {
        Route::post('stagiaire/profil', [AuthController::class, 'completeStagiaireProfile']);
    });
    
    Route::middleware('profil:entreprise')->group(function () {
        Route::post('entreprise/profil', [AuthController::class, 'completeEntrepriseProfile']);
    });
    
    // ============================================
    // RÉFÉRENTIEL (protégé mais accessible à tous)
    // ============================================
    Route::prefix('referentiel')->group(function () {
        Route::get('domaines', [ReferentielController::class, 'domaines']);
        Route::get('metiers', [ReferentielController::class, 'metiers']);
        Route::get('niveaux-formation', [ReferentielController::class, 'niveauxFormation']);
        Route::get('competences', [ReferentielController::class, 'competences']);
    });
    
    // ============================================
    // CRITÈRES SAVOIR-ÊTRE (accessibles aux deux)
    // ============================================
    Route::get('criteres-savoir-etre', [CritereSavoirEtreController::class, 'index']);
    
    // ============================================
    // ROUTES STAGIAIRE UNIQUEMENT
    // ============================================
    Route::middleware('profil:stagiaire')->group(function () {
        
        // Carnet de stage
        Route::prefix('carnets')->group(function () {
            Route::post('/', [CarnetController::class, 'store']);
            Route::get('/', [CarnetController::class, 'index']);
        });
        
        // Rattachement
        Route::post('rattacher-carnet', [RattachementController::class, 'rattacher']);
        
        // Pointage
        Route::prefix('pointage')->group(function () {
            Route::post('arrivee', [PointageController::class, 'arrivee']);
            Route::post('depart', [PointageController::class, 'depart']);
            Route::get('{carnetId}/historique', [PointageController::class, 'historique']);
        });
        
        // Documents
        Route::get('mes-attestations', [DocumentController::class, 'mesAttestations']);
        
        // Bilan réflexif
        Route::prefix('bilans-reflexifs')->group(function () {
            Route::post('/', [BilanReflexifController::class, 'store']);
            Route::get('carnets/{carnetId}/bilans-reflexifs', [BilanReflexifController::class, 'index']);
        });
        
        // ==========================================
        // COVOITURAGE - Stagiaire
        // ==========================================
        // Trajets
        Route::prefix('trajets')->group(function () {
            Route::post('/', [TrajetController::class, 'store']);
            Route::get('/', [TrajetController::class, 'index']);
            Route::get('mes-trajets', [TrajetController::class, 'mesTrajets']);
        });
        
        // Réservations
        Route::prefix('reservations')->group(function () {
            Route::post('{trajetId}/reserver', [ReservationController::class, 'store']);
            Route::post('{reservationId}/annuler', [ReservationController::class, 'annuler']);
            Route::get('mes-reservations', [ReservationController::class, 'mesReservations']);
        });
        
        // Messagerie
        Route::prefix('trajets/{trajetId}/messages')->group(function () {
            Route::post('/', [MessageController::class, 'store']);
            Route::get('/', [MessageController::class, 'index']);
        });
        
        // Signalement
        Route::post('trajets/{trajetId}/signaler', [SignalementController::class, 'store']);
    });
    
    // ============================================
    // ROUTES ENTREPRISE UNIQUEMENT
    // ============================================
    Route::middleware('profil:entreprise')->group(function () {
        
        // Fiches d'invitation
        Route::prefix('fiches-invitation')->group(function () {
            Route::post('/', [FicheStagiaireInviteController::class, 'store']);
            Route::get('/', [FicheStagiaireInviteController::class, 'index']);
        });
        
        // Évaluations compétences
        Route::prefix('evaluations')->group(function () {
            Route::post('/', [EvaluationController::class, 'store']);
            Route::get('carnets/{carnetId}/evaluations', [EvaluationController::class, 'index']);
        });
        
        // Documents (entreprise)
        Route::prefix('documents')->group(function () {
            Route::post('evaluations/{evaluationId}/attestation', [DocumentController::class, 'genererAttestation']);
            Route::post('evaluations/{evaluationId}/carte-appui', [DocumentController::class, 'genererCarteAppui']);
        });
        
        // Critères savoir-être (entreprise)
        Route::prefix('criteres-savoir-etre')->group(function () {
            Route::post('/', [CritereSavoirEtreController::class, 'store']);
        });
        
        // Évaluations savoir-être
        Route::prefix('evaluations-savoir-etre')->group(function () {
            Route::post('/', [EvaluationSavoirEtreController::class, 'store']);
            Route::get('carnets/{carnetId}/evaluations-savoir-etre', [EvaluationSavoirEtreController::class, 'index']);
        });
    });
});

// ================================================
// PROFILE TEST (à garder pour débogage)
// ================================================
Route::middleware('auth:sanctum')->get('/profil/moi', function (Request $request) {
    $user = $request->user();
    return response()->json([
        'id' => $user->id,
        'email' => $user->email,
        'role' => $user->role,
        'type' => get_class($user),
    ]);
=======

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
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
});