<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('entreprises', function (Blueprint $table) {

            $table->uuid('id')->primary();

            $table->string('email')->unique();

            $table->string('raison_sociale',150)->nullable();

            $table->string('secteur',100)->nullable();

            $table->string('adresse_libelle')->nullable();

            $table->decimal('adresse_lat',10,7)->nullable();

            $table->decimal('adresse_lng',10,7)->nullable();

            $table->integer('rayon_detection_metres')->default(100);

            $table->time('heure_debut_journee')->nullable();

            $table->time('heure_fin_journee')->nullable();

            $table->time('pause_heure_debut')->nullable();

            $table->time('pause_heure_fin')->nullable();

            $table->timestamp('date_creation_compte')->useCurrent();

            $table->timestamp('derniere_connexion')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('entreprises');
    }
};