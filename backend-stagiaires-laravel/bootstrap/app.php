<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
<<<<<<< HEAD
use Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful;
=======
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
<<<<<<< HEAD
        // Ajouter Sanctum pour l'API
        $middleware->api(prepend: [
            EnsureFrontendRequestsAreStateful::class,
        ]);

        // Vos middlewares personnalisés
        $middleware->alias([
            'profil' => \App\Http\Middleware\EnsureProfil::class,
        ]);
=======
        $middleware->alias([
        'profil' => \App\Http\Middleware\EnsureProfil::class,
    ]);
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );
<<<<<<< HEAD
    })->create();
=======
    })->create();
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
