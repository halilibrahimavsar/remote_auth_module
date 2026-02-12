/// Firebase BLoC Auth - A flexible, theme-aware Firebase authentication module.
///
/// Provides BLoC-based auth state management with optional UI pages.
/// Supports multi-Firebase-app configurations and clean architecture patterns.
library;

// Core
export 'src/core/exceptions/auth_exceptions.dart';

// Domain
export 'src/domain/entities/auth_user.dart';
export 'src/domain/repositories/auth_repository.dart';

// Data
export 'src/data/repositories/firebase_auth_repository.dart';

// Services
export 'src/services/firestore_user_service.dart';

// BLoC
export 'src/bloc/auth_bloc.dart';
export 'src/bloc/auth_event.dart';
export 'src/bloc/auth_state.dart';

// Presentation (Optional)
export 'src/presentation/pages/login_page.dart';
export 'src/presentation/pages/register_page.dart';
export 'src/presentation/pages/forgot_password_page.dart';
export 'src/presentation/widgets/confirm_dialog.dart';
