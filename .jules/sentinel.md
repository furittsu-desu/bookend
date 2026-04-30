## 2026-04-30 - Exporting encrypted fields as plaintext
**Vulnerability:** The application was exporting sensitive user data, particularly the `journal` box, completely unencrypted to the system clipboard during the backup process, even though it was stored encrypted in Hive.
**Learning:** Data exported from encrypted storage solutions must be encrypted prior to leaving the application boundaries to prevent unauthorized access.
**Prevention:** Encrypt the entire JSON payload utilizing the existing AES-256 secure key before converting it to a Base64-encoded string for clipboard export.
