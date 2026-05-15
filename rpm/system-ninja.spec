Name:       system-ninja
Summary:    System monitoring dashboard for Sailfish OS
Version:    1.0.0
Release:    1
License:    MIT
URL:        https://github.com/Andrew21P/system-ninja
Source0:    %{name}-%{version}.tar.gz
Requires:   pyotherside-qml-plugin-python3-qt5 >= 1.5
Requires:   sailfishsilica-qt5 >= 1.0
BuildArch:  noarch

%description
A lean native system monitor for Sailfish OS. Built entirely on-device
on a Sony Xperia XA2. Live CPU, RAM, storage, battery, network, thermal
and process stats with smooth animations and a polished cover.

%prep
%setup -q

%build
# Nothing to build - pure QML + Python

%install
rm -rf %{buildroot}

# App files
mkdir -p %{buildroot}/usr/share/%{name}
cp -r *.qml *.py *.sh cover pages %{buildroot}/usr/share/%{name}/
cp app-icon.png %{buildroot}/usr/share/%{name}/

# Desktop file
mkdir -p %{buildroot}/usr/share/applications
cp system-ninja.desktop %{buildroot}/usr/share/applications/

# Icons
mkdir -p %{buildroot}/usr/share/icons/hicolor/86x86/apps
mkdir -p %{buildroot}/usr/share/icons/hicolor/108x108/apps
mkdir -p %{buildroot}/usr/share/icons/hicolor/128x128/apps
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps

cp app-icon.png %{buildroot}/usr/share/icons/hicolor/86x86/apps/%{name}.png
cp app-icon.png %{buildroot}/usr/share/icons/hicolor/108x108/apps/%{name}.png
cp app-icon.png %{buildroot}/usr/share/icons/hicolor/128x128/apps/%{name}.png
cp app-icon.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/%{name}.png

%files
%defattr(-,root,root,-)
/usr/share/%{name}
/usr/share/applications/%{name}.desktop
/usr/share/icons/hicolor/*/apps/%{name}.png
