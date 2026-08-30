class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final String? endpoint;
  final DateTime timestamp;

  ApiException(
    this.message, {
    this.statusCode,
    this.errors,
    this.endpoint,
  }) : timestamp = DateTime.now() {
    // Print détaillé pour le debug en développement
    if (statusCode == 422 && errors != null) {
      print('--- API VALIDATION ERROR (422) ---');
      print('Endpoint: $endpoint');
      print('Errors: $errors');
      print('----------------------------------');
    }
  }

  // ============================================
  // FABRIQUES
  // ============================================

  /// Créer une exception à partir d'une réponse HTTP
  factory ApiException.fromResponse(
    int statusCode,
    Map<String, dynamic> response, [
    String? endpoint,
  ]) {
    final message = response['message'] ?? 'Erreur inconnue';
    final errors = response['errors'] as Map<String, dynamic>?;

    return ApiException(
      message,
      statusCode: statusCode,
      errors: errors,
      endpoint: endpoint,
    );
  }

  /// Créer une exception de connexion
  factory ApiException.networkError([String? endpoint]) {
    return ApiException(
      'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      statusCode: 0,
      endpoint: endpoint,
    );
  }

  /// Créer une exception de timeout
  factory ApiException.timeout([String? endpoint]) {
    return ApiException(
      'La requête a pris trop de temps. Veuillez réessayer.',
      statusCode: 408,
      endpoint: endpoint,
    );
  }

  /// Créer une exception de validation
  factory ApiException.validation(Map<String, dynamic> errors, [String? endpoint]) {
    final firstError = errors.values.first.first;
    return ApiException(
      firstError,
      statusCode: 422,
      errors: errors,
      endpoint: endpoint,
    );
  }

  // ============================================
  // GETTERS
  // ============================================

  /// Vérifier si c'est une erreur de validation (422)
  bool get isValidationError => statusCode == 422;

  /// Vérifier si c'est une erreur de non-authentification (401)
  bool get isUnauthorized => statusCode == 401;

  /// Vérifier si c'est une erreur de non-autorisation (403)
  bool get isForbidden => statusCode == 403;

  /// Vérifier si c'est une erreur de ressource non trouvée (404)
  bool get isNotFound => statusCode == 404;

  /// Vérifier si c'est une erreur de conflit (409)
  bool get isConflict => statusCode == 409;

  /// Vérifier si c'est une erreur serveur (500+)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Vérifier si c'est une erreur réseau (0)
  bool get isNetworkError => statusCode == 0;

  /// Vérifier si c'est une erreur de timeout (408)
  bool get isTimeout => statusCode == 408;

  /// Obtenir les erreurs de validation sous forme de liste
  ///
  /// Important : `errors` provient d'un `jsonDecode`, donc chaque valeur
  /// est un `List<dynamic>` (même si tous les éléments sont des String).
  /// Un cast direct `as List<String>` fonctionne sur la VM Dart native,
  /// mais lève une TypeError en mode web (compilateur DDC, strict sur les
  /// génériques à l'exécution). On caste donc élément par élément via
  /// `.toString()`, ce qui fonctionne de façon identique en web et natif.
  List<String> get validationErrors {
    if (errors == null) return [];
    return errors!.values
        .expand((e) => (e as List).map((item) => item.toString()))
        .toList();
  }

  /// Obtenir le message d'erreur principal
  String get userFriendlyMessage {
    if (isNetworkError) {
      return 'Impossible de se connecter au serveur.';
    }
    if (isTimeout) {
      return 'La requête a pris trop de temps.';
    }
    if (isUnauthorized) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }
    if (isForbidden) {
      return 'Vous n\'avez pas les droits nécessaires.';
    }
    if (isNotFound) {
      return 'La ressource demandée n\'existe pas.';
    }
    if (isValidationError) {
      return validationErrors.isNotEmpty ? validationErrors.first : message;
    }
    if (isServerError) {
      return 'Une erreur est survenue sur le serveur. Veuillez réessayer plus tard.';
    }
    return message;
  }

  // ============================================
  // OVERRIDE
  // ============================================

  @override
  String toString() {
    var buffer = StringBuffer('ApiException');
    if (statusCode != null) buffer.write(' [$statusCode]');
    buffer.write(': $message');
    if (endpoint != null) buffer.write(' (endpoint: $endpoint)');
    if (errors != null && errors!.isNotEmpty) {
      buffer.write('\nErreurs: $errors');
    }
    return buffer.toString();
  }

  // ============================================
  // TO MAP
  // ============================================

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'statusCode': statusCode,
      'errors': errors,
      'endpoint': endpoint,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}