// MissingTypes.swift
// ULTRA MINIMAL - Only what's absolutely necessary and doesn't exist elsewhere

import Foundation

// Empty file for now - all types we need already exist in:
// - Generated Types.swift
// - NearTypesBridge.swift
// - Other existing files

// If you need custom types, add them here without duplicating existing ones

// Finality tipada para usar .final / .optimistic / .near_hyphen_final
public enum Finality: String, Codable, Equatable {
    case final
    case optimistic
    case near_hyphen_final = "near-final"
}
