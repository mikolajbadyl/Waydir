#include "system_scale.h"

#include <gio/gio.h>
#include <gtk/gtk.h>
#include <stdlib.h>
#include <string.h>

#include <cmath>

namespace {

constexpr char kMethodChannel[] = "waydir/system_scale";
constexpr char kEventChannel[] = "waydir/system_scale/events";

struct ScaleState {
  FlEventChannel* event_channel = nullptr;
  bool listening = false;
  GtkSettings* gtk_settings = nullptr;
  gulong xft_dpi_handler = 0;
  GSettings* gnome_iface = nullptr;
  gulong gnome_handler = 0;
  double last = 1.0;
};

static ScaleState* g_state = nullptr;

static double clamp_scale(double v) {
  if (!std::isfinite(v) || v <= 0) return 1.0;
  if (v < 0.5) return 0.5;
  if (v > 4.0) return 4.0;
  return v;
}

static double read_xft_dpi_scale() {
  GtkSettings* settings = gtk_settings_get_default();
  if (!settings) return 1.0;
  gint xft_dpi = -1;
  g_object_get(settings, "gtk-xft-dpi", &xft_dpi, nullptr);
  if (xft_dpi <= 0) return 1.0;
  // gtk-xft-dpi is in 1024ths of a point. 96 DPI baseline.
  double dpi = xft_dpi / 1024.0;
  return clamp_scale(dpi / 96.0);
}

static double read_gnome_text_scale() {
  GSettingsSchemaSource* src = g_settings_schema_source_get_default();
  if (!src) return 1.0;
  GSettingsSchema* schema = g_settings_schema_source_lookup(
      src, "org.gnome.desktop.interface", TRUE);
  if (!schema) return 1.0;
  if (!g_settings_schema_has_key(schema, "text-scaling-factor")) {
    g_settings_schema_unref(schema);
    return 1.0;
  }
  g_settings_schema_unref(schema);
  GSettings* iface = g_settings_new("org.gnome.desktop.interface");
  double v = g_settings_get_double(iface, "text-scaling-factor");
  g_object_unref(iface);
  return clamp_scale(v);
}

static double read_env_scale() {
  const char* gdk_dpi = g_getenv("GDK_DPI_SCALE");
  if (gdk_dpi && *gdk_dpi) {
    char* end = nullptr;
    double v = strtod(gdk_dpi, &end);
    if (end != gdk_dpi && v > 0) return clamp_scale(v);
  }
  return 1.0;
}

static double compute_scale() {
  // text-scaling-factor takes precedence (accessibility).
  // Otherwise derive from gtk-xft-dpi or env GDK_DPI_SCALE.
  double gnome = read_gnome_text_scale();
  if (gnome != 1.0) return gnome;
  double xft = read_xft_dpi_scale();
  if (xft != 1.0) return xft;
  return read_env_scale();
}

static void emit_scale(double scale) {
  if (!g_state) return;
  g_state->last = scale;
  if (g_state->event_channel && g_state->listening) {
    g_autoptr(FlValue) v = fl_value_new_float(scale);
    fl_event_channel_send(g_state->event_channel, v, nullptr, nullptr);
  }
}

static void on_settings_changed(GObject*, GParamSpec*, gpointer) {
  emit_scale(compute_scale());
}

static void on_gnome_changed(GSettings*, gchar*, gpointer) {
  emit_scale(compute_scale());
}

static void method_call_cb(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const gchar* name = fl_method_call_get_name(call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(name, "getScale") == 0) {
    g_autoptr(FlValue) v = fl_value_new_float(compute_scale());
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(v));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  g_autoptr(GError) error = nullptr;
  fl_method_call_respond(call, response, &error);
}

static FlMethodErrorResponse* listen_cb(FlEventChannel*, FlValue*, gpointer) {
  if (!g_state) return nullptr;
  g_state->listening = true;
  emit_scale(compute_scale());
  return nullptr;
}

static FlMethodErrorResponse* cancel_cb(FlEventChannel*, FlValue*, gpointer) {
  if (g_state) g_state->listening = false;
  return nullptr;
}

}  // namespace

void system_scale_register(FlView* view) {
  if (g_state != nullptr) return;
  g_state = new ScaleState();

  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) method_codec = fl_standard_method_codec_new();
  FlMethodChannel* method_channel = fl_method_channel_new(
      messenger, kMethodChannel, FL_METHOD_CODEC(method_codec));
  fl_method_channel_set_method_call_handler(
      method_channel, method_call_cb, nullptr, nullptr);

  g_autoptr(FlStandardMethodCodec) event_codec = fl_standard_method_codec_new();
  g_state->event_channel = fl_event_channel_new(
      messenger, kEventChannel, FL_METHOD_CODEC(event_codec));
  fl_event_channel_set_stream_handlers(
      g_state->event_channel, listen_cb, cancel_cb, nullptr, nullptr);

  g_state->gtk_settings = gtk_settings_get_default();
  if (g_state->gtk_settings) {
    g_state->xft_dpi_handler = g_signal_connect(
        g_state->gtk_settings, "notify::gtk-xft-dpi",
        G_CALLBACK(on_settings_changed), nullptr);
  }

  GSettingsSchemaSource* src = g_settings_schema_source_get_default();
  if (src) {
    GSettingsSchema* schema = g_settings_schema_source_lookup(
        src, "org.gnome.desktop.interface", TRUE);
    if (schema) {
      g_state->gnome_iface = g_settings_new("org.gnome.desktop.interface");
      g_state->gnome_handler = g_signal_connect(
          g_state->gnome_iface, "changed::text-scaling-factor",
          G_CALLBACK(on_gnome_changed), nullptr);
      g_settings_schema_unref(schema);
    }
  }
}
