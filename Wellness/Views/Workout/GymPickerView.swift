//
//  GymPickerView.swift
//  Wellness
//
//  Sheet that lets a user tag a gym (or any place) on a workout. Two
//  paths into a selection:
//   1. **Nearby Gyms** — `MKLocalSearch` for "gym" within ~5 km of the
//      user's current location. Shown when location permission is
//      granted and we have a coordinate fix.
//   2. **Search** — free-text query resolved via `MKLocalSearchCompleter`
//      for live autocompletion. Works with no location permission.
//
//  Selecting a row returns a `WorkoutLocation` (or `nil` if the user
//  taps "Remove Gym") to the parent via the `onSelect` closure.
//

import CoreLocation
import MapKit
import SwiftUI

// MARK: - GymPickerView

struct GymPickerView: View {
    /// Existing selection — used to drive the "Remove" CTA so the user
    /// can untag a gym without replacing it.
    let current: WorkoutLocation?
    /// Callback with the user's choice. Parent dismisses the sheet.
    let onSelect: (WorkoutLocation?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var locationManager

    @State private var query: String = ""
    @State private var completerDelegate = CompleterDelegate()
    @State private var nearbyLoader       = NearbyGymLoader()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchField
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if !query.isEmpty {
                                suggestionsSection
                            }
                            if query.isEmpty {
                                nearbySection
                            }

                            if current != nil {
                                removeGymRow
                                    .padding(.top, 20)
                                    .padding(.bottom, 8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Tag a Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .preferredColorScheme(.dark)
            .keyboardDoneToolbar()
            .onAppear {
                locationManager.requestLocationIfNeeded()
                completerDelegate.configure()
                if let coord = locationManager.coordinate {
                    nearbyLoader.load(near: coord)
                }
            }
            .onChange(of: locationManager.coordinate?.latitude) { _, _ in
                if let coord = locationManager.coordinate {
                    nearbyLoader.load(near: coord)
                }
            }
            .onChange(of: query) { _, newQuery in
                completerDelegate.setQuery(newQuery,
                                           near: locationManager.coordinate)
            }
        }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.50))
            TextField("", text: $query, prompt:
                Text("Search gyms or places")
                    .foregroundStyle(.white.opacity(0.40))
            )
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .foregroundStyle(.white)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardBg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    // MARK: - Sections

    @ViewBuilder
    private var suggestionsSection: some View {
        sectionHeader("RESULTS")
        if completerDelegate.suggestions.isEmpty {
            placeholderRow("No matches yet — keep typing.")
        } else {
            ForEach(completerDelegate.suggestions, id: \.self) { suggestion in
                suggestionRow(suggestion)
                divider
            }
        }
    }

    @ViewBuilder
    private var nearbySection: some View {
        sectionHeader("NEARBY GYMS")
        if locationManager.coordinate == nil {
            placeholderRow("Share your location to see nearby gyms.")
        } else if nearbyLoader.isLoading && nearbyLoader.items.isEmpty {
            placeholderRow("Finding gyms near you…")
        } else if nearbyLoader.items.isEmpty {
            placeholderRow("No gyms found within 5 km.")
        } else {
            ForEach(nearbyLoader.items) { item in
                nearbyRow(item)
                divider
            }
        }
    }

    private var removeGymRow: some View {
        Button {
            onSelect(nil)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.85))
                Text("Remove Gym")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.90))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBg, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Row builders

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .black))
            .tracking(1.5)
            .foregroundStyle(.white.opacity(0.45))
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private func placeholderRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.40))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func nearbyRow(_ item: NearbyGymLoader.Result) -> some View {
        Button {
            onSelect(WorkoutLocation(
                name: item.name,
                address: item.address,
                latitude: item.coordinate.latitude,
                longitude: item.coordinate.longitude
            ))
            dismiss()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ThemeStore.shared.accent.opacity(0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeStore.shared.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if !item.address.isEmpty {
                        Text(item.address)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let distance = item.distanceMeters {
                    Text(Self.formatDistance(distance))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.40))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func suggestionRow(_ suggestion: MKLocalSearchCompletion) -> some View {
        Button {
            resolveAndSelect(suggestion)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.60))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion → coordinate lookup

    /// `MKLocalSearchCompletion` only gives us a display pair; resolve to
    /// a full `MKMapItem` (with a coordinate) via a follow-up
    /// `MKLocalSearch` before we can return a `WorkoutLocation`.
    private func resolveAndSelect(_ suggestion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: suggestion)
        let search  = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let item = response?.mapItems.first else { return }
            let coord   = item.placemark.coordinate
            let name    = item.name ?? suggestion.title
            let address = Self.formatAddress(item.placemark)
            Task { @MainActor in
                onSelect(WorkoutLocation(name: name, address: address,
                                         latitude: coord.latitude,
                                         longitude: coord.longitude))
                dismiss()
            }
        }
    }

    // MARK: - Formatting helpers

    private static func formatAddress(_ placemark: MKPlacemark) -> String {
        var parts: [String] = []
        if let s = placemark.thoroughfare {
            if let n = placemark.subThoroughfare { parts.append("\(n) \(s)") }
            else                                 { parts.append(s) }
        }
        if let city = placemark.locality { parts.append(city) }
        return parts.joined(separator: ", ")
    }

    private static func formatDistance(_ meters: Double) -> String {
        if meters < 1000 { return "\(Int(meters)) m" }
        let km = meters / 1000
        return String(format: km < 10 ? "%.1f km" : "%.0f km", km)
    }
}

// MARK: - MKLocalSearchCompleter driver

/// `@Observable` wrapper around `MKLocalSearchCompleter` so the SwiftUI
/// view re-renders whenever the suggestion list changes.
@Observable
final class CompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()
    private var isConfigured = false

    /// Installing the delegate here (rather than in init) avoids a retain
    /// cycle warning when SwiftUI recreates the @State wrapper.
    func configure() {
        guard !isConfigured else { return }
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
        isConfigured = true
    }

    func setQuery(_ query: String, near coordinate: CLLocationCoordinate2D?) {
        if let coord = coordinate {
            // Bias results around the user when we have a coordinate.
            completer.region = MKCoordinateRegion(
                center: coord,
                latitudinalMeters:  50_000,
                longitudinalMeters: 50_000
            )
        }
        if query.isEmpty {
            suggestions = []
            completer.cancel()
        } else {
            completer.queryFragment = query
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}

// MARK: - Nearby Gyms loader

/// Wraps a single `MKLocalSearch` for the "gym" query around a given
/// coordinate. Results are `Observable`-backed so the view updates when
/// the search completes.
@Observable
final class NearbyGymLoader {

    struct Result: Identifiable {
        let id = UUID()
        let name:       String
        let address:    String
        let coordinate: CLLocationCoordinate2D
        /// Meters from the query coordinate. nil when not computed.
        let distanceMeters: Double?
    }

    var items: [Result] = []
    var isLoading: Bool = false

    private var lastCoord: CLLocationCoordinate2D?

    /// Only refetches if the caller's coordinate has moved ≥ ~200m from
    /// the last query — the user's position drifts a few meters idly and
    /// re-running the search on every micro-update is wasteful.
    func load(near coordinate: CLLocationCoordinate2D) {
        if let last = lastCoord,
           CLLocation(latitude: last.latitude, longitude: last.longitude)
             .distance(from: CLLocation(latitude: coordinate.latitude,
                                        longitude: coordinate.longitude)) < 200 {
            return
        }
        lastCoord = coordinate
        isLoading = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "gym"
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters:  5_000,
            longitudinalMeters: 5_000
        )

        let origin = CLLocation(latitude: coordinate.latitude,
                                longitude: coordinate.longitude)

        MKLocalSearch(request: request).start { [weak self] response, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.isLoading = false }
                let mapItems = response?.mapItems ?? []
                self.items = mapItems.map { item in
                    let loc = CLLocation(latitude: item.placemark.coordinate.latitude,
                                         longitude: item.placemark.coordinate.longitude)
                    return Result(
                        name:       item.name ?? "Gym",
                        address:    Self.formatAddress(item.placemark),
                        coordinate: item.placemark.coordinate,
                        distanceMeters: loc.distance(from: origin)
                    )
                }
                .sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude)
                        < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
            }
        }
    }

    private static func formatAddress(_ placemark: MKPlacemark) -> String {
        var parts: [String] = []
        if let s = placemark.thoroughfare {
            if let n = placemark.subThoroughfare { parts.append("\(n) \(s)") }
            else                                 { parts.append(s) }
        }
        if let city = placemark.locality { parts.append(city) }
        return parts.joined(separator: ", ")
    }
}
