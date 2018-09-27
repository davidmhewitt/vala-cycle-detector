project('vala-cycle-detector', 'vala', 'c')

glib_dep = dependency('glib-2.0', version: '>=2.30.0')
gee_dep = dependency('gee-0.8', version: '>=0.8.5')
gvc_dep = dependency('libgvc')

add_project_arguments('--define=WITH_CGRAPH', language : 'vala')

# We need libvala-X.XX library, but it changes depending on the version that is installed
# Plus development versions are odd numbers registered as even
vala_versions = meson.get_compiler('vala').version().split('.')
vala_major = vala_versions[0]
vala_minor_int = vala_versions[1].to_int()
if vala_minor_int.is_odd()
    vala_minor_int = vala_minor_int + 1
endif

vala_name = 'libvala-@0@.@1@'.format(vala_major, vala_minor_int)
vala_dep = dependency(vala_name)

dependencies = [
    glib_dep,
    gee_dep,
    gvc_dep,
    vala_dep
]

subdir('src')
