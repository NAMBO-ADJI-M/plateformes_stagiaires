<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('code_confirmation_entreprise', function (Blueprint $table) {

            $table->uuid('id')->primary();

            $table->foreignUuid('entreprise_id')
                  ->nullable()
                  ->constrained('entreprises')
                  ->nullOnDelete();
            $table->string('code',10);

            $table->boolean('utilise')->default(false);

            $table->timestamp('date_generation')->useCurrent();

            $table->timestamp('date_expiration');

        });
    }

    public function down(): void
    {
        Schema::dropIfExists('code_confirmation_stagiaire');
    }
};