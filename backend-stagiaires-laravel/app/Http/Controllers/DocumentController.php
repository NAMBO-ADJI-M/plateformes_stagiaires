<?php

namespace App\Http\Controllers;

use App\Models\EvaluationCompetence;
use App\Models\Attestation;
use App\Models\CarteAppuiStage;
use Illuminate\Http\Request;

class DocumentController extends Controller
{
    // Génère l'attestation seule (le tuteur peut s'arrêter là)
    public function genererAttestation(Request $request, string $evaluationId)
    {
        $evaluation = EvaluationCompetence::where('id', $evaluationId)
            ->where('entreprise_id', $request->user()->id)
            ->with('carnet')
            ->firstOrFail();

        $attestation = Attestation::firstOrCreate(
            ['evaluation_id' => $evaluation->id],
            [
                'carnet_id' => $evaluation->carnet_id,
                'stagiaire_id' => $evaluation->carnet->stagiaire_id,
                'document_genere' => null, // TODO : génération PDF réelle, plus tard
            ]
        );

        return response()->json([
            'attestation' => $attestation,
            'proposition' => 'Souhaitez-vous aussi générer une carte d’appui stage pour ce stagiaire ?',
        ], 201);
    }

    // Génère la carte d'appui stage, séparément, sur décision du tuteur après l'attestation
    public function genererCarteAppui(Request $request, string $evaluationId)
    {
        $data = $request->validate([
            'entreprise_destinataire_nom' => 'required|string|max:150',
            'entreprise_destinataire_email' => 'required|email',
            'recommandation' => 'nullable|string',
        ]);

        $evaluation = EvaluationCompetence::where('id', $evaluationId)
            ->where('entreprise_id', $request->user()->id)
            ->firstOrFail();

        $carte = CarteAppuiStage::create([
            'evaluation_id' => $evaluation->id,
            'carnet_id' => $evaluation->carnet_id,
            'entreprise_emettrice_id' => $request->user()->id,
            'entreprise_destinataire_nom' => $data['entreprise_destinataire_nom'],
            'entreprise_destinataire_email' => $data['entreprise_destinataire_email'],
            'recommandation' => $data['recommandation'] ?? null,
            'document_genere' => null, // TODO : génération PDF réelle, plus tard
        ]);

        return response()->json($carte, 201);
    }

    // Le stagiaire consulte ses attestations reçues
    public function mesAttestations(Request $request)
    {
        return Attestation::where('stagiaire_id', $request->user()->id)
            ->orderByDesc('date_generation')
            ->get();
    }
}
