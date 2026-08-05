<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('attestations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('carnet_de_stage_id')
                 ->nullable()
                 ->constrained('carnets_de_stage')
                 ->onDelete('cascade');
            $table->foreignId('evaluations_id')
                 ->nullable()
                 ->constrained('fiches_stagiaire_invites')
                 ->onDelete('cascade');
            $
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attestations');
    }
};
