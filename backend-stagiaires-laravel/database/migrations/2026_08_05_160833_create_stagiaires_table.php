<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stagiaires', function (Blueprint $table) {

            $table->uuid('id')->primary();

            $table->string('email')->unique();

            $table->string('nom',100);

            $table->string('prenom',100);

            $table->string('photo_profil',500)->nullable();

            $table->string('domicile_adresse')->nullable();

            $table->decimal('domicile_lat',10,7)->nullable();

            $table->decimal('domicile_lng',10,7)->nullable();

            $table->boolean('autorisation_entraide')->default(false);

            $table->timestamp('date_premiere_connexion')->nullable();

            $table->timestamp('derniere_connexion')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stagiaires');
    }
};