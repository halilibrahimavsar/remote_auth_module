/// Firebase remote auth module
/// A flexible, theme-aware Firebase authentication module.
///
/// Provides BLoC-based auth state management with optional UI pages.
/// Supports multi-Firebase-app configurations and clean architecture patterns.
library;

export 'src/core/storage/secure_storage_service.dart';
export 'src/data/repositories/firebase_auth_repository.dart';
export 'src/domain/entities/auth_user.dart';
export 'src/domain/failures/auth_failure.dart';
export 'src/domain/repositories/auth_repository.dart';
export 'src/presentation/bloc/auth_bloc.dart';
export 'src/presentation/bloc/auth_event.dart';
export 'src/presentation/bloc/auth_state.dart';
export 'src/presentation/pages/change_password_page.dart';
export 'src/presentation/pages/email_verification_page.dart';
export 'src/presentation/pages/forgot_password_page.dart';
export 'src/presentation/pages/login_page.dart';
export 'src/presentation/pages/register_page.dart';
export 'src/presentation/templates/remote_auth_flow.dart';
export 'src/presentation/widgets/confirm_dialog.dart';
export 'src/services/firestore_user_service.dart';
export 'src/services/remember_me_service.dart';
