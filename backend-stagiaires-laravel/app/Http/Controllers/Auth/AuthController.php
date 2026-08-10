<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Stagiaire;
use App\Models\Entreprise;
use App\Models\VerificationCode;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Carbon\Carbon;

class AuthController extends Controller
{
    /**
     * 1️⃣ LOGIN - CRÉATION AUTO SI COMPTE N'EXISTE PAS
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|min:8',
            'role' => 'required|in:stagiaire,entreprise',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $email = $request->email;
        $password = $request->password;
        $role = $request->role;

        // 🔍 Vérifier si le compte existe
        $user = User::where('email', $email)->first();

        // ✅ 1️⃣ SI LE COMPTE N'EXISTE PAS → LE CRÉER
        if (!$user) {
            $user = User::create([
                'email' => $email,
                'password' => Hash::make($password),
                'role' => $role,
            ]);

            // Créer le profil selon le rôle
            if ($role === 'stagiaire') {
                Stagiaire::create([
                    'user_id' => $user->id,
                    'email' => $user->email,
                    'nom' => 'Utilisateur',
                    'prenom' => 'StageLink',
                    'profil_complet' => false,
                    'carnet_creer' => false,
                ]);
            } else {
                Entreprise::create([
                    'user_id' => $user->id,
                    'email' => $user->email,
                    'raison_sociale' => 'Mon Entreprise',
                    'profil_complet' => false,
                ]);
            }

            // ✅ 2️⃣ ENVOYER LE CODE DE VÉRIFICATION
            $code = $this->generateCode($user->email);
            $this->sendVerificationEmail($user->email, $code);

            return response()->json([
                'message' => '✅ Compte créé avec succès ! Un code de vérification a été envoyé à votre email.',
                'data' => [
                    'email' => $user->email,
                    'role' => $user->role,
                    'requires_verification' => true,
                    'code_sent' => true,
                    'code_expires_in' => 900,
                    'is_new_account' => true,
                ]
            ], 201);
        }

        // ✅ 3️⃣ SI LE COMPTE EXISTE → VÉRIFIER LE MOT DE PASSE
        if (!Hash::check($password, $user->password)) {
            return response()->json([
                'message' => '❌ Mot de passe incorrect',
                'errors' => ['password' => ['Le mot de passe saisi est incorrect.']]
            ], 422);
        }

        // ✅ 4️⃣ SI LE COMPTE EST DÉJÀ VÉRIFIÉ → CONNEXION DIRECTE
        if ($user->email_verified_at) {
            $token = $user->createToken('auth-token')->plainTextToken;
            $user->update(['last_login_at' => Carbon::now()]);

            return response()->json([
                'message' => '✅ Connexion réussie',
                'data' => [
                    'token' => $token,
                    'user' => $user,
                    'redirect' => $user->role === 'stagiaire' 
                        ? '/stagiaire/dashboard' 
                        : '/entreprise/dashboard',
                ]
            ]);
        }

        // ✅ 5️⃣ SI LE COMPTE N'EST PAS VÉRIFIÉ → RENVOYER LE CODE
        $code = $this->generateCode($user->email);
        $this->sendVerificationEmail($user->email, $code);

        return response()->json([
            'message' => '📧 Un code de vérification a été envoyé à votre email',
            'data' => [
                'email' => $user->email,
                'role' => $user->role,
                'requires_verification' => true,
                'code_sent' => true,
                'code_expires_in' => 900,
            ]
        ], 403);
    }

    /**
     * 2️⃣ VÉRIFICATION EMAIL
     */
    public function verify(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
            'code' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        // Vérifier le code
        $verification = VerificationCode::where('email', $request->email)
            ->where('code', $request->code)
            ->where('used', false)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$verification) {
            return response()->json([
                'message' => '❌ Code invalide ou expiré',
                'errors' => ['code' => ['Le code saisi est incorrect ou a expiré.']]
            ], 422);
        }

        // Marquer comme utilisé
        $verification->update(['used' => true]);

        // Activer le compte
        $user = User::where('email', $request->email)->first();
        $user->update([
            'email_verified_at' => Carbon::now(),
            'last_login_at' => Carbon::now(),
        ]);

        // Générer le token
        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'message' => '✅ Email vérifié avec succès !',
            'data' => [
                'token' => $token,
                'user' => $user,
                'redirect' => $user->role === 'stagiaire' 
                    ? '/stagiaire/dashboard' 
                    : '/entreprise/dashboard',
            ]
        ]);
    }

    /**
     * 3️⃣ INSCRIPTION (DÉPRÉCIÉE - UTILISER LOGIN)
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:8',
            'role' => 'required|in:stagiaire,entreprise',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
        ]);

        if ($request->role === 'stagiaire') {
            Stagiaire::create([
                'user_id' => $user->id,
                'email' => $user->email,
                'nom' => 'Utilisateur',
                'prenom' => 'StageLink',
                'profil_complet' => false,
                'carnet_creer' => false,
            ]);
        } else {
            Entreprise::create([
                'user_id' => $user->id,
                'email' => $user->email,
                'raison_sociale' => 'Mon Entreprise',
                'profil_complet' => false,
            ]);
        }

        $code = $this->generateCode($user->email);
        $this->sendVerificationEmail($user->email, $code);

        return response()->json([
            'message' => '✅ Compte créé avec succès ! Un code de vérification a été envoyé à votre email.',
            'data' => [
                'email' => $user->email,
                'role' => $user->role,
                'requires_verification' => true,
                'code_expires_in' => 900,
            ]
        ], 201);
    }

    /**
     * 4️⃣ DÉCONNEXION
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => '✅ Déconnexion réussie'
        ]);
    }

    /**
     * 5️⃣ RENVOYER LE CODE
     */
    public function resendCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::where('email', $request->email)->first();

        if ($user->email_verified_at) {
            return response()->json([
                'message' => '✅ Ce compte est déjà vérifié',
                'verified' => true,
            ], 422);
        }

        $code = $this->generateCode($user->email);
        $this->sendVerificationEmail($user->email, $code);

        return response()->json([
            'message' => '📧 Un nouveau code de vérification a été envoyé à votre email',
            'data' => [
                'email' => $user->email,
                'expires_in' => '15 minutes',
            ]
        ]);
    }

    /**
     * 6️⃣ PROFIL UTILISATEUR
     */
    public function profile(Request $request)
    {
        $user = $request->user();
        $profile = $this->getProfileStatus($user);

        return response()->json([
            'user' => $user,
            'profile_status' => $profile,
            'profile_data' => $user->role === 'stagiaire' 
                ? $user->stagiaire 
                : $user->entreprise
        ]);
    }

    /**
     * 7️⃣ COMPLÉTER LE PROFIL STAGIAIRE
     */
    public function completeStagiaireProfile(Request $request)
    {
        $user = $request->user();
        
        if ($user->role !== 'stagiaire') {
            return response()->json([
                'message' => 'Accès réservé au profil : stagiaire'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'nom' => 'required|string|max:100',
            'prenom' => 'required|string|max:100',
            'date_naissance' => 'nullable|date',
            'telephone' => 'nullable|string|max:50',
            'adresse' => 'nullable|string|max:255',
            'ecole' => 'nullable|string|max:100',
            'filiere' => 'nullable|string|max:100',
            'niveau' => 'nullable|string|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $stagiaire = Stagiaire::where('user_id', $user->id)->first();
        
        if (!$stagiaire) {
            return response()->json([
                'message' => 'Profil stagiaire non trouvé'
            ], 404);
        }

        $stagiaire->update([
            'nom' => $request->nom,
            'prenom' => $request->prenom,
            'date_naissance' => $request->date_naissance,
            'telephone' => $request->telephone,
            'domicile_adresse' => $request->adresse,
            'ecole' => $request->ecole,
            'filiere' => $request->filiere,
            'niveau' => $request->niveau,
            'profil_complet' => true,
        ]);

        return response()->json([
            'message' => '✅ Profil complété avec succès !',
            'data' => $stagiaire
        ]);
    }

    /**
     * 8️⃣ COMPLÉTER LE PROFIL ENTREPRISE
     */
    public function completeEntrepriseProfile(Request $request)
    {
        $user = $request->user();
        
        if ($user->role !== 'entreprise') {
            return response()->json([
                'message' => 'Accès réservé au profil : entreprise'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'raison_sociale' => 'required|string|max:150',
            'secteur' => 'nullable|string|max:100',
            'adresse_libelle' => 'nullable|string|max:255',
            'telephone' => 'nullable|string|max:50',
            'site_web' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        $entreprise = Entreprise::where('user_id', $user->id)->first();
        
        if (!$entreprise) {
            return response()->json([
                'message' => 'Profil entreprise non trouvé'
            ], 404);
        }

        $entreprise->update([
            'raison_sociale' => $request->raison_sociale,
            'secteur' => $request->secteur,
            'adresse_libelle' => $request->adresse_libelle,
            'telephone' => $request->telephone,
            'site_web' => $request->site_web,
            'profil_complet' => true,
        ]);

        return response()->json([
            'message' => '✅ Profil entreprise complété avec succès !',
            'data' => $entreprise
        ]);
    }

    // ================================================
    // 🔧 MÉTHODES PRIVÉES
    // ================================================

    /**
     * Générer un code de vérification à 6 chiffres
     */
    private function generateCode(string $email): string
    {
        // Supprimer les anciens codes non utilisés
        VerificationCode::where('email', $email)
            ->where('used', false)
            ->delete();

        // Générer un code à 6 chiffres
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Sauvegarder le code
        VerificationCode::create([
            'id' => (string) Str::uuid(),
            'email' => $email,
            'code' => $code,
            'type' => 'registration',
            'used' => false,
            'expires_at' => Carbon::now()->addMinutes(15),
        ]);

        return $code;
    }

    /**
     * Envoyer l'email de vérification
     */
    private function sendVerificationEmail(string $email, string $code): void
    {
        try {
            Mail::send('emails.verification', [
                'code' => $code,
                'email' => $email
            ], function ($message) use ($email) {
                $message->to($email)
                    ->subject('🔐 Vérifiez votre compte StageLink')
                    ->from('noreply@stagelink.com', 'StageLink');
            });
        } catch (\Exception $e) {
            // Log l'erreur mais ne bloque pas le processus
            \Log::error('Erreur d\'envoi d\'email: ' . $e->getMessage());
        }
    }

    /**
     * Obtenir le statut du profil utilisateur
     */
    private function getProfileStatus(User $user): array
    {
        if ($user->role === 'stagiaire') {
            $stagiaire = Stagiaire::where('user_id', $user->id)->first();
            $profilComplet = $stagiaire->profil_complet ?? false;
            $carnetCree = $stagiaire->carnet_creer ?? false;
            
            return [
                'profile_complete' => $profilComplet,
                'carnet_created' => $carnetCree,
                'next_step' => $profilComplet ? 'carnet' : 'profile',
                'message' => $profilComplet 
                    ? 'Créez votre carnet de stage' 
                    : 'Complétez votre profil'
            ];
        } else {
            $entreprise = Entreprise::where('user_id', $user->id)->first();
            $profilComplet = $entreprise->profil_complet ?? false;
            
            return [
                'profile_complete' => $profilComplet,
                'next_step' => $profilComplet ? 'dashboard' : 'profile',
                'message' => $profilComplet 
                    ? 'Gérez vos stagiaires' 
                    : 'Complétez votre profil entreprise'
            ];
        }
    }
}