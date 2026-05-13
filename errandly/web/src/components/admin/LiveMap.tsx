'use client';
import { MapContainer, TileLayer, Marker, Popup, Circle } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix leaflet default marker icons
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

const runnerIcon = new L.DivIcon({
  html: `<div style="background:#16A34A;width:28px;height:28px;border-radius:50%;border:3px solid white;display:flex;align-items:center;justify-content:center;color:white;font-size:14px;box-shadow:0 2px 8px rgba(0,0,0,0.3)">🏃</div>`,
  iconSize: [28, 28],
  className: '',
});

const errandIcon = new L.DivIcon({
  html: `<div style="background:#FF6B00;width:28px;height:28px;border-radius:50%;border:3px solid white;display:flex;align-items:center;justify-content:center;color:white;font-size:14px;box-shadow:0 2px 8px rgba(0,0,0,0.3)">📦</div>`,
  iconSize: [28, 28],
  className: '',
});

const panicIcon = new L.DivIcon({
  html: `<div style="background:#DC2626;width:32px;height:32px;border-radius:50%;border:3px solid white;display:flex;align-items:center;justify-content:center;color:white;font-size:16px;box-shadow:0 2px 12px rgba(220,38,38,0.6);animation:pulse 1s infinite">🚨</div>`,
  iconSize: [32, 32],
  className: '',
});

interface Props {
  runners: any[];
  errands: any[];
  panics: any[];
}

export default function LiveMap({ runners, errands, panics }: Props) {
  const LAGOS_CENTER: [number, number] = [6.5244, 3.3792];

  return (
    <MapContainer center={LAGOS_CENTER} zoom={12} style={{ height: '100%', width: '100%' }}>
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />

      {/* Service areas */}
      {[
        { name: 'Lekki', lat: 6.4698, lng: 3.5852, radius: 10000 },
        { name: 'Yaba', lat: 6.5058, lng: 3.3767, radius: 8000 },
        { name: 'Ikeja', lat: 6.5955, lng: 3.3401, radius: 10000 },
        { name: 'Surulere', lat: 6.5059, lng: 3.3534, radius: 8000 },
        { name: 'Victoria Island', lat: 6.4281, lng: 3.4219, radius: 7000 },
      ].map((area) => (
        <Circle
          key={area.name}
          center={[area.lat, area.lng]}
          radius={area.radius}
          pathOptions={{ color: '#FF6B00', fillColor: '#FF6B00', fillOpacity: 0.05, weight: 1 }}
        />
      ))}

      {/* Online runners */}
      {runners.map((runner: any) => (
        runner.current_latitude && runner.current_longitude ? (
          <Marker
            key={runner.user_id}
            position={[runner.current_latitude, runner.current_longitude]}
            icon={runnerIcon}
          >
            <Popup>
              <div className="p-1">
                <p className="font-bold">{runner.user?.first_name} {runner.user?.last_name}</p>
                <p className="text-sm text-gray-600">Trust: {runner.trust_score}/100</p>
                <p className="text-sm text-gray-600">{runner.is_available ? '✅ Available' : '⏳ On errand'}</p>
              </div>
            </Popup>
          </Marker>
        ) : null
      ))}

      {/* Active errands */}
      {errands.map((errand: any) => (
        errand.pickup_latitude ? (
          <Marker
            key={errand.id}
            position={[errand.pickup_latitude, errand.pickup_longitude]}
            icon={errandIcon}
          >
            <Popup>
              <div className="p-1">
                <p className="font-bold">{errand.title}</p>
                <p className="text-sm text-gray-600">{errand.status?.replace(/_/g, ' ')}</p>
                <p className="text-sm text-gray-600">Customer: {errand.customer?.first_name}</p>
              </div>
            </Popup>
          </Marker>
        ) : null
      ))}

      {/* Panic events */}
      {panics.map((panic: any) => (
        panic.latitude ? (
          <Marker
            key={panic.id}
            position={[panic.latitude, panic.longitude]}
            icon={panicIcon}
          >
            <Popup>
              <div className="p-1">
                <p className="font-bold text-red-700">🚨 PANIC ALERT</p>
                <p className="text-sm">{panic.errand?.title}</p>
                <p className="text-sm">By: {panic.triggered_by?.first_name}</p>
              </div>
            </Popup>
          </Marker>
        ) : null
      ))}
    </MapContainer>
  );
}
