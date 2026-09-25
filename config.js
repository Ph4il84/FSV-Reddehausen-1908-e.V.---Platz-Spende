// Trage hier eure Supabase-Zugangsdaten ein (Projekt-Einstellungen -> API).
// Der "anon public key" ist bewusst öffentlich sichtbar -- Zugriffsrechte
// werden ausschließlich über die Row-Level-Security-Regeln in schema.sql geregelt.

const SUPABASE_URL = "https://saeywgqgxhsitdwdtrxp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNhZXl3Z3FneGhzaXRkd2R0cnhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5MDIxNjEsImV4cCI6MjEwNTQ3ODE2MX0.rjcPHnEd2GzHWM54xfZU5DDa1ca4i1cPH0GhhHFBASc";

// Benachrichtigung an den Verein bei neuer Reservierung läuft seit Umstellung
// über die Supabase Edge Function "notify-reservation" (Brevo), nicht mehr über EmailJS.
// EmailJS wird nur noch für die manuelle Zahlungsaufforderung im Admin-Bereich genutzt.
const EMAILJS_PUBLIC_KEY = "rMa-xDBDs6DtsRMUR";
const EMAILJS_SERVICE_ID = "service_1ssixgn";
const EMAILJS_TEMPLATE_ID_SPONSOR = "template_z7bimno";
