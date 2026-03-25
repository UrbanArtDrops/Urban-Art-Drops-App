import "package:flutter/material.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

/// A password field that only exposes the visibility toggle after input exists.
class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    required this.controller,
    required this.decoration,
    super.key,
    this.enabled,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final bool? enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant PasswordTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_handleTextChanged);
    widget.controller.addListener(_handleTextChanged);
    if (!_hasValue) {
      _obscureText = true;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  bool get _hasValue => widget.controller.text.isNotEmpty;

  void _handleTextChanged() {
    if (_hasValue) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (!_obscureText) {
      setState(() => _obscureText = true);
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canToggleVisibility = _hasValue;

    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      onSubmitted: widget.onSubmitted,
      obscureText: _obscureText,
      decoration: widget.decoration.copyWith(
        suffixIcon: canToggleVisibility
            ? IconButton(
                tooltip: _obscureText
                    ? l10n.showPasswordAction
                    : l10n.hidePasswordAction,
                onPressed: () {
                  setState(() => _obscureText = !_obscureText);
                },
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    );
  }
}
