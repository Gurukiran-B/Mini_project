# TODO: Add Realtime Location-Based Routing

## Backend Updates
- [x] Update OptimalRouteInput model to include start_lat, start_lng, end_lat, end_lng
- [ ] Add new endpoint /real_route for coordinate-based routing
- [x] Enhance hybrid_route to handle real coordinates (simulate with predefined cities)
- [ ] Update traffic prediction to use location coordinates

## Frontend Updates
- [ ] Add Location model (lat, lng)
- [x] Update OptimalRouteInput model to include coordinates
- [x] Add geolocator dependency to pubspec.yaml
- [x] Create location service for getting current location
- [x] Modify MapScreen to add start/destination input fields with current location option
- [x] Integrate delivery search with routing (use current location as start)
- [ ] Update ApiService for new real_route endpoint
- [ ] Add realtime location tracking for delivery users
- [ ] Enhance map widget to show route with coordinates
- [ ] Add maps prediction feature for normal users

## Testing
- [ ] Test location permissions and services
- [ ] Test routing with real coordinates
- [ ] Test delivery integration
- [ ] Test predictions
- [ ] Ensure no data loss and backward compatibility
