Name:       system-ninja
Summary:    System monitoring dashboard for Sailfish OS
Version:    1.0.1
Release:    1
License:    MIT
URL:        https://github.com/Andrew21P/system-ninja
Source0:    %{name}-%{version}.tar.gz
Requires:   pyotherside-qml-plugin-python3-qt5
Requires:   sailfishsilica-qt5
Requires:   qt5-qtdeclarative-qmlscene
Requires:   qtchooser
BuildArch:  noarch

# Disable brp scripts that fail with BusyBox xargs
%define __strip /bin/true
%define __brp_compress /bin/true
%define __brp_strip /bin/true
%define __brp_strip_static_archive /bin/true

%description
A lean native system monitor for Sailfish OS. Live CPU, RAM, storage,
battery, network, thermal and process stats with smooth animations
and a polished cover.

%prep
%setup -q

%build
# Pure QML + Python, nothing to compile

%install
rm -rf %{buildroot}

# Application files
mkdir -p %{buildroot}/usr/share/%{name}
cp main.qml backend.py launch.sh app-icon.png %{buildroot}/usr/share/%{name}/
cp -r cover pages %{buildroot}/usr/share/%{name}/

# Desktop entry
mkdir -p %{buildroot}/usr/share/applications
cp %{name}.desktop %{buildroot}/usr/share/applications/

# Icons
for size in 86x86 108x108 128x128 256x256; do
    mkdir -p %{buildroot}/usr/share/icons/hicolor/$size/apps
    cp app-icon.png %{buildroot}/usr/share/icons/hicolor/$size/apps/%{name}.png
done

%files
%defattr(-,root,root,-)
/usr/share/%{name}
/usr/share/applications/%{name}.desktop
/usr/share/icons/hicolor/*/apps/%{name}.png
