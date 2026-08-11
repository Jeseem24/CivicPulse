/**
 * Geo Service — Spatial intelligence utilities
 * Haversine distance, nearby complaints, density, hotspots
 */

/**
 * Haversine distance between two lat/lng points in kilometers
 */
function haversineDistance(lat1, lng1, lat2, lng2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Find nearby complaints within a radius
 * @param {Array} complaints - All complaints
 * @param {number} lat
 * @param {number} lng
 * @param {number} radiusKm - Default 2km
 * @returns {Array}
 */
function getNearbyComplaints(complaints, lat, lng, radiusKm = 2) {
  return complaints
    .filter(c => c.location && c.location.lat && c.location.lng)
    .map(c => ({
      ...c,
      distanceKm: Math.round(haversineDistance(lat, lng, c.location.lat, c.location.lng) * 100) / 100
    }))
    .filter(c => c.distanceKm <= radiusKm)
    .sort((a, b) => a.distanceKm - b.distanceKm);
}

/**
 * Get complaint density at a point
 */
function getComplaintDensity(complaints, lat, lng, radiusKm = 1) {
  const nearby = getNearbyComplaints(complaints, lat, lng, radiusKm);
  return {
    count: nearby.length,
    radiusKm,
    density: nearby.length > 0 ? Math.round(nearby.length / (Math.PI * radiusKm * radiusKm) * 100) / 100 : 0,
    complaints: nearby.map(c => ({ id: c.id, title: c.title, status: c.status, distanceKm: c.distanceKm }))
  };
}

/**
 * Identify complaint hotspots using simple grid-based clustering
 * @param {Array} complaints
 * @param {number} gridSizeKm - Clustering grid size
 * @returns {Array} Hotspots sorted by complaint count
 */
function getHotspots(complaints, gridSizeKm = 0.5) {
  const grid = new Map();
  const factor = 1 / (gridSizeKm / 111); // approx degrees per km at equator

  for (const c of complaints) {
    if (!c.location || !c.location.lat || !c.location.lng) continue;
    const gridKey = `${Math.round(c.location.lat * factor)}:${Math.round(c.location.lng * factor)}`;
    if (!grid.has(gridKey)) {
      grid.set(gridKey, { complaints: [], lat: 0, lng: 0 });
    }
    const cell = grid.get(gridKey);
    cell.complaints.push({ id: c.id, title: c.title, category: c.category, status: c.status, priority: c.priority });
    cell.lat += c.location.lat;
    cell.lng += c.location.lng;
  }

  return Array.from(grid.values())
    .map(cell => ({
      count: cell.complaints.length,
      center: {
        lat: Math.round((cell.lat / cell.complaints.length) * 10000) / 10000,
        lng: Math.round((cell.lng / cell.complaints.length) * 10000) / 10000
      },
      complaints: cell.complaints
    }))
    .filter(h => h.count >= 2)
    .sort((a, b) => b.count - a.count);
}

module.exports = { haversineDistance, getNearbyComplaints, getComplaintDensity, getHotspots };
