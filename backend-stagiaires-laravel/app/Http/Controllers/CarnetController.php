<?php

namespace App\Http\Controllers;

use App\Models\CarnetDeStage;
use Illuminate\Http\Request;

class CarnetController extends Controller
{
    // Crée un carnet en autonomie, sans entreprise rattachée
    public function store(Request $request)
    {
        $data = $request->validate([
            'domaine_formation_id' => 'required|string|exists:domaines_formation,id',
            'metier_id' => 'required|string|exists:metiers,id',
            'niveau_formation_id' => 'required|string|exists:niveaux_formation,id',
            'date_debut' => 'nullable|date',
            'date_fin' => 'nullable|date|after:date_debut',
        ]);

        $carnet = CarnetDeStage::create([
            ...$data,
            'stagiaire_id' => $request->user()->id,
        ]);

        return response()->json($carnet, 201);
    }

    // Liste tous les carnets du stagiaire connecté (plusieurs stages possibles en simultané)
    public function index(Request $request)
    {
        return CarnetDeStage::where('stagiaire_id', $request->user()->id)
            ->with(['stagiaire:id,nom,prenom']) // exemple de relation chargée
            ->orderByDesc('date_creation')
            ->get();
    }
}
