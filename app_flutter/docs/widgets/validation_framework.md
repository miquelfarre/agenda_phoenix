# Validation Framework - Documentación Detallada

## 1. Información General

**Ubicación**: `/lib/widgets/adaptive/validation_framework.dart`

**Propósito**: Framework de validación que proporciona validadores predefinidos para campos de texto (email, password, phone, etc.) y herramientas para combinarlos. Implementa el patrón Strategy para validación mediante la interfaz `TextFieldValidator` definida en `adaptive_text_field.dart`.

**Tipo de archivo**: Implementaciones concretas de validadores + clase de utilidades

**Líneas de código**: 236

**Clases contenidas**: 9 clases
- 8 validadores concretos (implementan TextFieldValidator)
- 1 clase de utilidades estáticas

---

## 2. Dependencias (Líneas 1-2)

```dart
import 'adaptive_card.dart';
import 'adaptive_text_field.dart';
```

**Importaciones**:

1. **`adaptive_card.dart`** (línea 1):
   - Proporciona: ValidationResult, ValidationIssue, ValidationSeverity
   - Usado por: Todos los validadores para retornar resultados

2. **`adaptive_text_field.dart`** (línea 2):
   - Proporciona: TextFieldValidator (interfaz abstracta)
   - Usado por: Todos los validadores implementan esta interfaz

**Nota**: Estas clases base (ValidationResult, ValidationIssue, ValidationSeverity, TextFieldValidator) están definidas en adaptive_card.dart, que es el archivo que define el sistema completo de validación.

---

## 3. EmailValidator (Líneas 4-21)

### 3.1. Propósito

Validador para direcciones de email que verifica el formato mediante expresión regular.

### 3.2. Clase completa

```dart
class EmailValidator extends TextFieldValidator {
  @override
  String get name => 'email';

  @override
  ValidationResult validate(String text) {
    if (text.isEmpty) {
      return ValidationResult.invalid([
        const ValidationIssue(
          message: 'Email is required',
          severity: ValidationSeverity.error
        )
      ]);
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(text)) {
      return ValidationResult.invalid([
        const ValidationIssue(
          message: 'Please enter a valid email address',
          severity: ValidationSeverity.error
        )
      ]);
    }

    return ValidationResult.valid();
  }
}
```

### 3.3. Propiedades

**`name`** (línea 6): Getter que retorna 'email' como identificador del validador

### 3.4. Método `validate()` (Líneas 9-20)

**Parámetro**: `text` - String a validar

**Retorno**: ValidationResult (válido o inválido con issues)

**Lógica en 2 pasos**:

1. **Verificación de vacío** (líneas 10-12):
   ```dart
   if (text.isEmpty) {
     return ValidationResult.invalid([
       const ValidationIssue(
         message: 'Email is required',
         severity: ValidationSeverity.error
       )
     ]);
   }
   ```
   - Si el texto está vacío: retorna inválido con mensaje "Email is required"

2. **Verificación de formato** (líneas 14-17):
   ```dart
   final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
   if (!emailRegex.hasMatch(text)) {
     return ValidationResult.invalid([...]);
   }
   ```

   **Regex explicada**: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
   - `^` - Inicio de string
   - `[a-zA-Z0-9._%+-]+` - Parte local: letras, números y caracteres especiales (._%+-)
   - `@` - Arroba literal
   - `[a-zA-Z0-9.-]+` - Dominio: letras, números, puntos y guiones
   - `\.` - Punto literal
   - `[a-zA-Z]{2,}` - Extensión: al menos 2 letras
   - `$` - Fin de string

   **Ejemplos válidos**: user@example.com, test.user+tag@domain.co.uk
   **Ejemplos inválidos**: @example.com, user@, user@domain, user@domain.a

3. **Validación exitosa** (línea 19):
   ```dart
   return ValidationResult.valid();
   ```
   - Si pasa ambas verificaciones: retorna válido

---

## 4. RequiredValidator (Líneas 23-39)

### 4.1. Propósito

Validador genérico para campos requeridos (no pueden estar vacíos). Permite personalizar el mensaje de error.

### 4.2. Clase completa

```dart
class RequiredValidator extends TextFieldValidator {
  final String? customMessage;

  RequiredValidator({this.customMessage});

  @override
  String get name => 'required';

  @override
  ValidationResult validate(String text) {
    if (text.trim().isEmpty) {
      return ValidationResult.invalid([
        ValidationIssue(
          message: customMessage ?? 'This field is required',
          severity: ValidationSeverity.error
        )
      ]);
    }

    return ValidationResult.valid();
  }
}
```

### 4.3. Propiedades

**`customMessage`** (línea 24): String? - Mensaje de error personalizado (opcional)

### 4.4. Constructor (Línea 26)

```dart
RequiredValidator({this.customMessage});
```

**Parámetros opcionales**:
- `customMessage`: Mensaje personalizado para el error

**Uso**:
```dart
RequiredValidator() // Mensaje por defecto
RequiredValidator(customMessage: 'El nombre es obligatorio') // Personalizado
```

### 4.5. Método `validate()` (Líneas 32-38)

**Lógica** (línea 33):
```dart
if (text.trim().isEmpty) {
  return ValidationResult.invalid([
    ValidationIssue(
      message: customMessage ?? 'This field is required',
      severity: ValidationSeverity.error
    )
  ]);
}
```

**Característica clave**: Usa `text.trim()` para eliminar espacios en blanco antes y después
- " " → inválido (solo espacios)
- "  text  " → válido (contiene texto)

**Mensaje de error**:
- Si `customMessage` está definido: usa ese mensaje
- Si no: usa mensaje por defecto "This field is required"

---

## 5. MinLengthValidator (Líneas 41-58)

### 5.1. Propósito

Validador que verifica que el texto tenga al menos una longitud mínima especificada.

### 5.2. Clase completa

```dart
class MinLengthValidator extends TextFieldValidator {
  final int minLength;
  final String? customMessage;

  MinLengthValidator(this.minLength, {this.customMessage});

  @override
  String get name => 'minLength';

  @override
  ValidationResult validate(String text) {
    if (text.length < minLength) {
      return ValidationResult.invalid([
        ValidationIssue(
          message: customMessage ?? 'Minimum length is $minLength characters',
          severity: ValidationSeverity.error
        )
      ]);
    }

    return ValidationResult.valid();
  }
}
```

### 5.3. Propiedades

1. **`minLength`** (línea 42): int - Longitud mínima requerida
2. **`customMessage`** (línea 43): String? - Mensaje de error personalizado (opcional)

### 5.4. Constructor (Línea 45)

```dart
MinLengthValidator(this.minLength, {this.customMessage});
```

**Parámetros**:
- `minLength` (posicional, requerido): Longitud mínima
- `customMessage` (named, opcional): Mensaje personalizado

**Uso**:
```dart
MinLengthValidator(8) // Mínimo 8 caracteres
MinLengthValidator(2, customMessage: 'Name must be at least 2 characters')
```

### 5.5. Método `validate()` (Líneas 51-57)

**Verificación** (línea 52):
```dart
if (text.length < minLength) {
  return ValidationResult.invalid([
    ValidationIssue(
      message: customMessage ?? 'Minimum length is $minLength characters',
      severity: ValidationSeverity.error
    )
  ]);
}
```

**Mensaje por defecto**: Usa interpolación de string para incluir la longitud mínima
- Ejemplo: "Minimum length is 8 characters"

**Característica**: NO usa trim(), cuenta todos los caracteres incluyendo espacios

---

## 6. MaxLengthValidator (Líneas 60-77)

### 6.1. Propósito

Validador que verifica que el texto no exceda una longitud máxima especificada.

### 6.2. Clase completa

```dart
class MaxLengthValidator extends TextFieldValidator {
  final int maxLength;
  final String? customMessage;

  MaxLengthValidator(this.maxLength, {this.customMessage});

  @override
  String get name => 'maxLength';

  @override
  ValidationResult validate(String text) {
    if (text.length > maxLength) {
      return ValidationResult.invalid([
        ValidationIssue(
          message: customMessage ?? 'Maximum length is $maxLength characters',
          severity: ValidationSeverity.error
        )
      ]);
    }

    return ValidationResult.valid();
  }
}
```

### 6.3. Propiedades

1. **`maxLength`** (línea 61): int - Longitud máxima permitida
2. **`customMessage`** (línea 62): String? - Mensaje de error personalizado (opcional)

### 6.4. Constructor (Línea 64)

```dart
MaxLengthValidator(this.maxLength, {this.customMessage});
```

**Parámetros**:
- `maxLength` (posicional, requerido): Longitud máxima
- `customMessage` (named, opcional): Mensaje personalizado

**Uso**:
```dart
MaxLengthValidator(100) // Máximo 100 caracteres
MaxLengthValidator(50, customMessage: 'Too long!')
```

### 6.5. Método `validate()` (Líneas 70-76)

**Verificación** (línea 71):
```dart
if (text.length > maxLength) {
  return ValidationResult.invalid([
    ValidationIssue(
      message: customMessage ?? 'Maximum length is $maxLength characters',
      severity: ValidationSeverity.error
    )
  ]);
}
```

**Complementario a MinLengthValidator**:
- MinLength: `text.length < minLength`
- MaxLength: `text.length > maxLength`

**Nota**: AdaptiveTextField también puede usar `maxLength` en su config para prevenir entrada (este validador valida después)

---

## 7. PhoneValidator (Líneas 79-97)

### 7.1. Propósito

Validador para números de teléfono que verifica que haya al menos 10 dígitos (ignora caracteres no numéricos como espacios, guiones, paréntesis).

### 7.2. Clase completa

```dart
class PhoneValidator extends TextFieldValidator {
  @override
  String get name => 'phone';

  @override
  ValidationResult validate(String text) {
    if (text.isEmpty) {
      return ValidationResult.invalid([
        const ValidationIssue(
          message: 'Phone number is required',
          severity: ValidationSeverity.error
        )
      ]);
    }

    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10) {
      return ValidationResult.invalid([
        const ValidationIssue(
          message: 'Phone number must have at least 10 digits',
          severity: ValidationSeverity.error
        )
      ]);
    }

    return ValidationResult.valid();
  }
}
```

### 7.3. Método `validate()` (Líneas 84-96)

**Lógica en 3 pasos**:

1. **Verificación de vacío** (líneas 85-87):
   ```dart
   if (text.isEmpty) {
     return ValidationResult.invalid([
       const ValidationIssue(
         message: 'Phone number is required',
         severity: ValidationSeverity.error
       )
     ]);
   }
   ```

2. **Extracción de dígitos** (línea 89):
   ```dart
   final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
   ```

   **Regex**: `\D` - Cualquier carácter que NO sea dígito
   **Acción**: Reemplaza todos los no-dígitos con string vacío

   **Ejemplos**:
   - "(555) 123-4567" → "5551234567" (10 dígitos)
   - "+1 555 123 4567" → "15551234567" (11 dígitos)
   - "555.123.4567" → "5551234567" (10 dígitos)

3. **Verificación de longitud** (líneas 91-93):
   ```dart
   if (digitsOnly.length < 10) {
     return ValidationResult.invalid([
       const ValidationIssue(
         message: 'Phone number must have at least 10 digits',
         severity: ValidationSeverity.error
       )
     ]);
   }
   ```

   **Mínimo**: 10 dígitos (estándar para la mayoría de países)
   **Permite**: Más de 10 dígitos (códigos de país, extensiones)

**Formatos aceptados**:
- 5551234567 ✓
- (555) 123-4567 ✓
- +1 555 123 4567 ✓
- 555-123-4567 ✓
- 12345 ✗ (menos de 10 dígitos)

---

## 8. PasswordValidator (Líneas 99-141)

### 8.1. Propósito

Validador avanzado de contraseñas con múltiples reglas configurables (longitud, mayúsculas, minúsculas, números, caracteres especiales). Puede retornar múltiples errores simultáneamente.

### 8.2. Clase completa

```dart
class PasswordValidator extends TextFieldValidator {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;

  PasswordValidator({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = false
  });

  @override
  String get name => 'password';

  @override
  ValidationResult validate(String text) {
    final issues = <ValidationIssue>[];

    if (text.length < minLength) {
      issues.add(ValidationIssue(
        message: 'Password must be at least $minLength characters',
        severity: ValidationSeverity.error
      ));
    }

    if (requireUppercase && !text.contains(RegExp(r'[A-Z]'))) {
      issues.add(const ValidationIssue(
        message: 'Password must contain uppercase letters',
        severity: ValidationSeverity.error
      ));
    }

    if (requireLowercase && !text.contains(RegExp(r'[a-z]'))) {
      issues.add(const ValidationIssue(
        message: 'Password must contain lowercase letters',
        severity: ValidationSeverity.error
      ));
    }

    if (requireNumbers && !text.contains(RegExp(r'[0-9]'))) {
      issues.add(const ValidationIssue(
        message: 'Password must contain numbers',
        severity: ValidationSeverity.error
      ));
    }

    if (requireSpecialChars && !text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      issues.add(const ValidationIssue(
        message: 'Password must contain special characters',
        severity: ValidationSeverity.error
      ));
    }

    if (issues.isNotEmpty) {
      return ValidationResult.invalid(issues);
    }

    return ValidationResult.valid();
  }
}
```

### 8.3. Propiedades (Líneas 100-105)

1. **`minLength`** (línea 100): int - Longitud mínima (default: 8)
2. **`requireUppercase`** (línea 101): bool - Requiere mayúsculas (default: true)
3. **`requireLowercase`** (línea 102): bool - Requiere minúsculas (default: true)
4. **`requireNumbers`** (línea 103): bool - Requiere números (default: true)
5. **`requireSpecialChars`** (línea 104): bool - Requiere caracteres especiales (default: false)

### 8.4. Constructor (Línea 106)

```dart
PasswordValidator({
  this.minLength = 8,
  this.requireUppercase = true,
  this.requireLowercase = true,
  this.requireNumbers = true,
  this.requireSpecialChars = false
});
```

**Todos los parámetros son opcionales** con valores por defecto

**Configuración por defecto**:
- Mínimo 8 caracteres
- Requiere mayúsculas
- Requiere minúsculas
- Requiere números
- NO requiere caracteres especiales

**Ejemplos de uso**:
```dart
PasswordValidator() // Configuración por defecto
PasswordValidator(minLength: 12, requireSpecialChars: true) // Más estricto
PasswordValidator(requireUppercase: false, requireNumbers: false) // Más permisivo
```

### 8.5. Método `validate()` (Líneas 112-140)

**Característica única**: Acumula TODOS los errores en una lista antes de retornar

**Estructura**:
1. Crea lista mutable de issues (línea 113)
2. Verifica cada regla y agrega issues
3. Retorna inválido con todos los issues o válido si no hay issues

**Verificaciones**:

**1. Longitud mínima** (líneas 115-117):
```dart
if (text.length < minLength) {
  issues.add(ValidationIssue(
    message: 'Password must be at least $minLength characters',
    severity: ValidationSeverity.error
  ));
}
```
- Mensaje usa interpolación: "Password must be at least 8 characters"

**2. Mayúsculas** (líneas 119-121):
```dart
if (requireUppercase && !text.contains(RegExp(r'[A-Z]'))) {
  issues.add(const ValidationIssue(
    message: 'Password must contain uppercase letters',
    severity: ValidationSeverity.error
  ));
}
```
- Regex: `[A-Z]` - Al menos una letra mayúscula
- Solo verifica si `requireUppercase` es true

**3. Minúsculas** (líneas 123-125):
```dart
if (requireLowercase && !text.contains(RegExp(r'[a-z]'))) {
  issues.add(const ValidationIssue(
    message: 'Password must contain lowercase letters',
    severity: ValidationSeverity.error
  ));
}
```
- Regex: `[a-z]` - Al menos una letra minúscula

**4. Números** (líneas 127-129):
```dart
if (requireNumbers && !text.contains(RegExp(r'[0-9]'))) {
  issues.add(const ValidationIssue(
    message: 'Password must contain numbers',
    severity: ValidationSeverity.error
  ));
}
```
- Regex: `[0-9]` - Al menos un dígito

**5. Caracteres especiales** (líneas 131-133):
```dart
if (requireSpecialChars && !text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
  issues.add(const ValidationIssue(
    message: 'Password must contain special characters',
    severity: ValidationSeverity.error
  ));
}
```
- Regex: `[!@#$%^&*(),.?":{}|<>]` - Al menos uno de estos caracteres especiales
- Caracteres permitidos: ! @ # $ % ^ & * ( ) , . ? " : { } | < >

**6. Retorno final** (líneas 135-139):
```dart
if (issues.isNotEmpty) {
  return ValidationResult.invalid(issues);
}

return ValidationResult.valid();
```
- Si hay issues: retorna inválido con TODOS los issues (no solo el primero)
- Si no hay issues: retorna válido

**Ejemplo de múltiples errores**:
```dart
final validator = PasswordValidator();
final result = validator.validate("abc"); // 3 caracteres, solo minúsculas

// result.issues contendrá 3 ValidationIssues:
// 1. "Password must be at least 8 characters"
// 2. "Password must contain uppercase letters"
// 3. "Password must contain numbers"
```

---

## 9. RegexValidator (Líneas 143-161)

### 9.1. Propósito

Validador genérico que permite usar cualquier expresión regular personalizada. Útil para casos de validación específicos no cubiertos por otros validadores.

### 9.2. Clase completa

```dart
class RegexValidator extends TextFieldValidator {
  final RegExp regex;
  final String message;
  final String validatorName;

  RegexValidator({
    required this.regex,
    required this.message,
    required this.validatorName
  });

  @override
  String get name => validatorName;

  @override
  ValidationResult validate(String text) {
    if (!regex.hasMatch(text)) {
      return ValidationResult.invalid([
        ValidationIssue(
          message: message,
          severity: ValidationSeverity.error
        )
      ]);
    }

    return ValidationResult.valid();
  }
}
```

### 9.3. Propiedades (Líneas 144-146)

1. **`regex`** (línea 144): RegExp - Expresión regular para validar
2. **`message`** (línea 145): String - Mensaje de error a mostrar
3. **`validatorName`** (línea 146): String - Nombre identificador del validador

### 9.4. Constructor (Líneas 148)

```dart
RegexValidator({
  required this.regex,
  required this.message,
  required this.validatorName
});
```

**Todos los parámetros son required** (no hay defaults lógicos para regex genérico)

**Uso**:
```dart
RegexValidator(
  regex: RegExp(r'^[A-Z]{2}\d{6}$'),
  message: 'Must be 2 uppercase letters followed by 6 digits',
  validatorName: 'customCode'
)
```

### 9.5. Método `validate()` (Líneas 154-160)

```dart
ValidationResult validate(String text) {
  if (!regex.hasMatch(text)) {
    return ValidationResult.invalid([
      ValidationIssue(
        message: message,
        severity: ValidationSeverity.error
      )
    ]);
  }

  return ValidationResult.valid();
}
```

**Lógica simple**:
- Si el regex NO coincide (`!regex.hasMatch(text)`): inválido con el mensaje proporcionado
- Si coincide: válido

**Casos de uso**:
- Códigos postales específicos de un país
- Formatos de documentos (DNI, pasaporte)
- Patrones personalizados de negocio
- Cualquier validación que no esté cubierta por validadores predefinidos

---

## 10. CompositeValidator (Líneas 163-192)

### 10.1. Propósito

Validador compuesto que ejecuta múltiples validadores en secuencia. Permite combinar validadores simples para crear validaciones complejas. Soporta dos modos: parar en el primer error o recolectar todos los errores.

### 10.2. Clase completa

```dart
class CompositeValidator extends TextFieldValidator {
  final List<TextFieldValidator> validators;
  final bool stopOnFirstError;

  CompositeValidator({
    required this.validators,
    this.stopOnFirstError = true
  });

  @override
  String get name => 'composite';

  @override
  ValidationResult validate(String text) {
    final allErrors = <ValidationIssue>[];

    for (final validator in validators) {
      final result = validator.validate(text);
      if (!result.isValid) {
        allErrors.addAll(result.issues);
        if (stopOnFirstError) {
          break;
        }
      }
    }

    if (allErrors.isNotEmpty) {
      return ValidationResult.invalid(allErrors);
    }

    return ValidationResult.valid();
  }
}
```

### 10.3. Propiedades (Líneas 164-165)

1. **`validators`** (línea 164): List<TextFieldValidator> - Lista de validadores a ejecutar
2. **`stopOnFirstError`** (línea 165): bool - Si parar en el primer error (default: true)

### 10.4. Constructor (Líneas 167)

```dart
CompositeValidator({
  required this.validators,
  this.stopOnFirstError = true
});
```

**Parámetros**:
- `validators` (required): Lista de validadores a combinar
- `stopOnFirstError` (optional, default true): Modo de ejecución

**Modos de operación**:
1. **stopOnFirstError = true**: Para en el primer validador que falle (más eficiente)
2. **stopOnFirstError = false**: Ejecuta todos los validadores (muestra todos los errores)

**Uso**:
```dart
CompositeValidator(validators: [
  RequiredValidator(),
  MinLengthValidator(8),
  PasswordValidator()
])

CompositeValidator(
  validators: [RequiredValidator(), EmailValidator()],
  stopOnFirstError: false // Muestra "required" Y "invalid email" si aplica
)
```

### 10.5. Método `validate()` (Líneas 173-191)

```dart
ValidationResult validate(String text) {
  final allErrors = <ValidationIssue>[];

  for (final validator in validators) {
    final result = validator.validate(text);
    if (!result.isValid) {
      allErrors.addAll(result.issues);
      if (stopOnFirstError) {
        break;
      }
    }
  }

  if (allErrors.isNotEmpty) {
    return ValidationResult.invalid(allErrors);
  }

  return ValidationResult.valid();
}
```

**Lógica paso a paso**:

1. **Inicialización** (línea 174):
   ```dart
   final allErrors = <ValidationIssue>[];
   ```
   - Lista mutable para acumular todos los errores

2. **Iteración de validadores** (líneas 176-184):
   ```dart
   for (final validator in validators) {
     final result = validator.validate(text);
     if (!result.isValid) {
       allErrors.addAll(result.issues);
       if (stopOnFirstError) {
         break;
       }
     }
   }
   ```
   - Ejecuta cada validador en orden
   - Si el resultado es inválido:
     - Agrega TODOS los issues del validador (usa `addAll`, no `add`)
     - Si `stopOnFirstError` es true: para inmediatamente con `break`
     - Si `stopOnFirstError` es false: continúa con el siguiente validador

3. **Retorno** (líneas 186-190):
   ```dart
   if (allErrors.isNotEmpty) {
     return ValidationResult.invalid(allErrors);
   }

   return ValidationResult.valid();
   ```
   - Si hay errores acumulados: retorna inválido con todos los issues
   - Si no hay errores: retorna válido (todos los validadores pasaron)

**Característica importante**: Usa `addAll(result.issues)` en lugar de `add(result)`
- Esto permite que si un validador individual (como PasswordValidator) retorna múltiples issues, todos se agreguen a la lista
- Mantiene la lista plana de ValidationIssues

**Ejemplo de comportamiento**:

```dart
// Modo: stopOnFirstError = true (default)
final validator = CompositeValidator(validators: [
  RequiredValidator(),
  MinLengthValidator(8),
  EmailValidator()
]);

validator.validate("") // Solo retorna error de RequiredValidator (para ahí)
validator.validate("abc") // Solo retorna error de MinLengthValidator (para ahí)
validator.validate("12345678") // Solo retorna error de EmailValidator

// Modo: stopOnFirstError = false
final validator2 = CompositeValidator(
  validators: [RequiredValidator(), MinLengthValidator(8), EmailValidator()],
  stopOnFirstError: false
);

validator2.validate("abc") // Retorna 2 errores: MinLength Y Email
```

---

## 11. ValidationUtils (Líneas 194-235)

### 11.1. Propósito

Clase de utilidades estáticas que proporciona:
1. Factory methods para combinaciones comunes de validadores
2. Utilidades para validar múltiples campos simultáneamente
3. Métodos helper para analizar resultados de validación

### 11.2. Factory Methods para Validadores Comunes

#### 11.2.1. `forEmail()` (Línea 195)

```dart
static List<TextFieldValidator> forEmail() => [
  RequiredValidator(),
  EmailValidator()
];
```

**Retorna**: Lista con validador de campo requerido + validador de email

**Uso**:
```dart
final validators = ValidationUtils.forEmail();
// Equivalente a: [RequiredValidator(), EmailValidator()]
```

#### 11.2.2. `forPassword()` (Línea 197)

```dart
static List<TextFieldValidator> forPassword() => [
  RequiredValidator(),
  PasswordValidator()
];
```

**Retorna**: Lista con validador de campo requerido + validador de password (con configuración por defecto)

**Uso**:
```dart
final validators = ValidationUtils.forPassword();
// Equivalente a: [RequiredValidator(), PasswordValidator()]
```

#### 11.2.3. `forPhone()` (Línea 199)

```dart
static List<TextFieldValidator> forPhone() => [
  RequiredValidator(),
  PhoneValidator()
];
```

**Retorna**: Lista con validador de campo requerido + validador de teléfono

#### 11.2.4. `forName()` (Línea 201)

```dart
static List<TextFieldValidator> forName() => [
  RequiredValidator(),
  MinLengthValidator(2, customMessage: 'Name must be at least 2 characters')
];
```

**Retorna**: Lista con validador de campo requerido + validador de longitud mínima (2 caracteres) con mensaje personalizado

**Uso común**:
```dart
AdaptiveTextField(
  config: TextFieldConfigs.firstName.copyWith(
    validators: ValidationUtils.forName()
  )
)
```

### 11.3. Validación de Múltiples Campos

#### 11.3.1. `validateFields()` (Líneas 203-220)

```dart
static Map<String, ValidationResult> validateFields(
  Map<String, String> fieldValues,
  Map<String, List<TextFieldValidator>> fieldValidators
) {
  final results = <String, ValidationResult>{};

  for (final entry in fieldValues.entries) {
    final fieldName = entry.key;
    final value = entry.value;
    final validators = fieldValidators[fieldName] ?? [];

    if (validators.isNotEmpty) {
      final composite = CompositeValidator(validators: validators);
      results[fieldName] = composite.validate(value);
    } else {
      results[fieldName] = ValidationResult.valid();
    }
  }

  return results;
}
```

**Propósito**: Validar múltiples campos de un formulario de una vez

**Parámetros**:
1. **`fieldValues`**: Map<String, String> - Valores de los campos (clave: nombre del campo, valor: texto ingresado)
2. **`fieldValidators`**: Map<String, List<TextFieldValidator>> - Validadores por campo

**Retorno**: Map<String, ValidationResult> - Resultados de validación por campo

**Lógica**:

1. **Inicialización** (línea 204):
   ```dart
   final results = <String, ValidationResult>{};
   ```

2. **Iteración por cada campo** (líneas 206-217):
   - Extrae nombre del campo, valor y validadores
   - Obtiene validadores para ese campo (usa `??` con lista vacía si no hay)

3. **Validación del campo** (líneas 211-216):
   ```dart
   if (validators.isNotEmpty) {
     final composite = CompositeValidator(validators: validators);
     results[fieldName] = composite.validate(value);
   } else {
     results[fieldName] = ValidationResult.valid();
   }
   ```
   - Si hay validadores: crea un CompositeValidator y valida
   - Si NO hay validadores: asume que el campo es válido

**Uso típico**:
```dart
final fieldValues = {
  'email': emailController.text,
  'password': passwordController.text,
  'name': nameController.text,
};

final fieldValidators = {
  'email': ValidationUtils.forEmail(),
  'password': ValidationUtils.forPassword(),
  'name': ValidationUtils.forName(),
};

final results = ValidationUtils.validateFields(fieldValues, fieldValidators);

if (ValidationUtils.areAllValid(results)) {
  // Enviar formulario
} else {
  // Mostrar errores
  final errors = ValidationUtils.getAllErrorMessages(results);
}
```

#### 11.3.2. `areAllValid()` (Líneas 222-224)

```dart
static bool areAllValid(Map<String, ValidationResult> results) {
  return results.values.every((result) => result.isValid);
}
```

**Propósito**: Verificar si todos los campos son válidos

**Parámetro**: Map<String, ValidationResult> - Resultados de validateFields()

**Retorno**: bool - true si TODOS son válidos, false si al menos uno es inválido

**Método**: Usa `every()` que retorna true solo si TODOS los elementos cumplen la condición

**Uso**:
```dart
final results = ValidationUtils.validateFields(fieldValues, fieldValidators);

if (ValidationUtils.areAllValid(results)) {
  print("Formulario válido, puede enviarse");
} else {
  print("Hay errores en el formulario");
}
```

#### 11.3.3. `getAllErrorMessages()` (Líneas 226-235)

```dart
static List<String> getAllErrorMessages(Map<String, ValidationResult> results) {
  final messages = <String>[];
  for (final result in results.values) {
    if (!result.isValid) {
      messages.addAll(result.issues.map((e) => e.message));
    }
  }
  return messages;
}
```

**Propósito**: Obtener una lista plana con todos los mensajes de error de todos los campos

**Parámetro**: Map<String, ValidationResult> - Resultados de validateFields()

**Retorno**: List<String> - Lista de mensajes de error (puede estar vacía)

**Lógica**:
1. Crea lista mutable de mensajes (línea 227)
2. Itera sobre los resultados (línea 228)
3. Para cada resultado inválido:
   - Mapea los issues a sus mensajes (línea 230)
   - Agrega todos los mensajes a la lista (usa `addAll`)
4. Retorna la lista de mensajes

**Característica**: Pierde la información de qué campo generó qué error (lista plana)

**Uso típico**:
```dart
final results = ValidationUtils.validateFields(fieldValues, fieldValidators);

if (!ValidationUtils.areAllValid(results)) {
  final errors = ValidationUtils.getAllErrorMessages(results);

  // Mostrar en un dialog o snackbar
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Errores de validación'),
      content: Column(
        children: errors.map((msg) => Text('• $msg')).toList(),
      ),
    ),
  );
}
```

**Ejemplo de salida**:
```dart
// Si email está vacío y password no cumple requisitos:
final errors = ValidationUtils.getAllErrorMessages(results);
// errors = [
//   'Email is required',
//   'Password must be at least 8 characters',
//   'Password must contain uppercase letters'
// ]
```

---

## 12. Resumen de Validadores

### 12.1. Tabla comparativa de validadores

| Validador | Parámetros | Configuración | Uso Principal |
|-----------|-----------|---------------|---------------|
| EmailValidator | Ninguno | Hardcoded | Validación de email con regex |
| RequiredValidator | customMessage? | Mensaje opcional | Campo no vacío (con trim) |
| MinLengthValidator | minLength, customMessage? | Longitud personalizable | Mínimo de caracteres |
| MaxLengthValidator | maxLength, customMessage? | Longitud personalizable | Máximo de caracteres |
| PhoneValidator | Ninguno | Hardcoded | Teléfono con ≥10 dígitos |
| PasswordValidator | 5 parámetros opcionales | Altamente configurable | Contraseñas complejas |
| RegexValidator | regex, message, name | Totalmente personalizable | Validaciones custom |
| CompositeValidator | validators, stopOnFirstError? | Combina otros validadores | Validaciones múltiples |

### 12.2. Validadores con múltiples errores posibles

| Validador | Puede retornar múltiples issues |
|-----------|----------------------------------|
| EmailValidator | No (máximo 1) |
| RequiredValidator | No (máximo 1) |
| MinLengthValidator | No (máximo 1) |
| MaxLengthValidator | No (máximo 1) |
| PhoneValidator | No (máximo 1) |
| **PasswordValidator** | **Sí (hasta 5)** |
| RegexValidator | No (máximo 1) |
| **CompositeValidator** | **Sí (acumula de otros)** |

### 12.3. Expresiones regulares usadas

| Validador | Regex | Propósito |
|-----------|-------|-----------|
| EmailValidator | `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$` | Formato de email completo |
| PhoneValidator | `\D` | Eliminar no-dígitos |
| PasswordValidator | `[A-Z]` | Al menos una mayúscula |
| PasswordValidator | `[a-z]` | Al menos una minúscula |
| PasswordValidator | `[0-9]` | Al menos un número |
| PasswordValidator | `[!@#$%^&*(),.?":{}|<>]` | Al menos un carácter especial |

### 12.4. Factory methods de ValidationUtils

| Método | Validadores incluidos |
|--------|----------------------|
| forEmail() | RequiredValidator + EmailValidator |
| forPassword() | RequiredValidator + PasswordValidator (default config) |
| forPhone() | RequiredValidator + PhoneValidator |
| forName() | RequiredValidator + MinLengthValidator(2) |

---

## 13. Características Técnicas

### 13.1. Patrón de diseño

**Patrón Strategy**: Cada validador es una estrategia intercambiable que implementa la interfaz `TextFieldValidator`

**Patrón Composite**: CompositeValidator implementa el patrón Composite para combinar validadores

**Factory Pattern**: ValidationUtils proporciona factory methods para crear combinaciones comunes

### 13.2. Inmutabilidad

**Validadores inmutables**:
- EmailValidator (sin propiedades)
- PhoneValidator (sin propiedades)

**Validadores configurables** (propiedades finales):
- RequiredValidator
- MinLengthValidator
- MaxLengthValidator
- PasswordValidator
- RegexValidator
- CompositeValidator

### 13.3. Mensajes de error

**Mensajes hardcoded** (const):
- EmailValidator: 2 mensajes fijos
- PhoneValidator: 2 mensajes fijos
- PasswordValidator: 5 mensajes (1 con interpolación)

**Mensajes personalizables**:
- RequiredValidator: `customMessage ?? 'This field is required'`
- MinLengthValidator: `customMessage ?? 'Minimum length is $minLength characters'`
- MaxLengthValidator: `customMessage ?? 'Maximum length is $maxLength characters'`
- RegexValidator: mensaje completamente personalizable

### 13.4. Optimizaciones

**Const ValidationIssues**: Varios validadores usan `const ValidationIssue(...)` cuando es posible

**Short-circuit**: CompositeValidator puede parar en el primer error (modo por defecto)

**Validación eficiente**:
- PhoneValidator elimina no-dígitos con regex (una sola pasada)
- EmailValidator verifica vacío antes de regex (optimización temprana)
- PasswordValidator acumula todos los errores en una sola pasada

### 13.5. Internacionalización

**NO soportada actualmente**: Todos los mensajes están en inglés hardcoded

**Solución para i18n**: Usar `customMessage` en validadores que lo soporten, o crear validadores custom que usen paquetes de internacionalización

### 13.6. Reutilización

**Composición sobre herencia**: Los validadores se componen usando CompositeValidator en lugar de heredar unos de otros

**Validadores reutilizables**: ValidationUtils.forEmail(), forPassword(), etc. son reutilizables en toda la app

**Sin estado**: Todos los validadores son stateless (pueden reutilizarse sin crear nuevas instancias)

---

## 14. Flujo de Uso Típico

### 14.1. Uso individual en un campo

```dart
AdaptiveTextField(
  config: AdaptiveTextFieldConfig(
    validators: [
      RequiredValidator(),
      EmailValidator()
    ]
  )
)
```

### 14.2. Uso con factory method

```dart
AdaptiveTextField(
  config: AdaptiveTextFieldConfig(
    validators: ValidationUtils.forEmail()
  )
)
```

### 14.3. Validación de formulario completo

```dart
void _validateForm() {
  final fieldValues = {
    'email': _emailController.text,
    'password': _passwordController.text,
    'name': _nameController.text,
  };

  final fieldValidators = {
    'email': ValidationUtils.forEmail(),
    'password': ValidationUtils.forPassword(),
    'name': ValidationUtils.forName(),
  };

  final results = ValidationUtils.validateFields(fieldValues, fieldValidators);

  if (ValidationUtils.areAllValid(results)) {
    // Submit form
    _submitForm();
  } else {
    // Show errors
    final errors = ValidationUtils.getAllErrorMessages(results);
    _showErrors(errors);
  }
}
```

### 14.4. Validador compuesto con configuración custom

```dart
CompositeValidator(
  validators: [
    RequiredValidator(customMessage: 'El email es obligatorio'),
    EmailValidator()
  ],
  stopOnFirstError: false // Mostrar ambos errores si aplica
)
```

---

**Fin de la documentación de validation_framework.dart**
