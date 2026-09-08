'use client';

import { MapContainer, TileLayer, Marker } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

delete (L.Icon.Default.prototype as unknown as { _getIconUrl?: unknown })._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

const pickupIcon = new L.DivIcon({
  html: '<div style="background:#FF6B00;width:24px;height:24px;border-radius:50%;border:2px solid white"></div>',
  iconSize: [24, 24],
  className: '',
});

const runnerIcon = new L.DivIcon({
  html: '<div style="background:#16A34A;width:24px;height:24px;border-radius:50%;border:2px solid white"></div>',
  iconSize: [24, 24],
  className: '',
});

type Props = {
  pickupLat: number;
  pickupLng: number;
  destLat: number;
  destLng: number;
  runnerLat?: number | null;
  runnerLng?: number | null;
};

export default function ErrandTrackingMap({
  pickupLat,
  pickupLng,
  destLat,
  destLng,
  runnerLat,
  runnerLng,
}: Props) {
  const center: [number, number] =
    runnerLat != null && runnerLng != null ? [runnerLat, runnerLng] : [pickupLat, pickupLng];

  return (
    <div className="h-48 w-full rounded-xl overflow-hidden border border-border">
      <MapContainer center={center} zoom={14} scrollWheelZoom={false} className="h-full w-full">
        <TileLayer url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <Marker position={[pickupLat, pickupLng]} icon={pickupIcon} />
        <Marker position={[destLat, destLng]} />
        {runnerLat != null && runnerLng != null && (
          <Marker position={[runnerLat, runnerLng]} icon={runnerIcon} />
        )}
      </MapContainer>
    </div>
  );
}
