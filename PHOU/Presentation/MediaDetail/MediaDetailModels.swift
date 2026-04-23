//
//  MediaDetailModels.swift
//  PHOU
//
//  Created by Codex on 4/24/26.
//

import Foundation

struct MediaAssetDetails: Equatable, Identifiable {
    let id: String
    let titlePrimaryText: String
    let titleSecondaryText: String
    let captureDateText: String
    let locationText: String
    let filenameText: String
    let deviceText: String
    let albumText: String
    let isFavorite: Bool
    let mediaTypeText: String
    let pixelSizeText: String

    static func placeholder(for asset: PhotoAsset) -> Self {
        let title = titleTexts(
            date: asset.creationDate,
            locationText: nil
        )
        return Self(
            id: asset.id,
            titlePrimaryText: title.primary,
            titleSecondaryText: title.secondary,
            captureDateText: Self.formattedInfoDate(asset.creationDate),
            locationText: "위치 없음",
            filenameText: "정보 확인 중",
            deviceText: "정보 확인 중",
            albumText: "정보 확인 중",
            isFavorite: asset.isFavorite,
            mediaTypeText: Self.mediaTypeText(asset.mediaType),
            pixelSizeText: "-"
        )
    }

    static func provisionalTitleTexts(date: Date?, hasLocation: Bool) -> (primary: String, secondary: String) {
        guard hasLocation else {
            return titleTexts(date: date, locationText: nil)
        }

        let formattedDate = formattedTitleDate(date)
        let formattedTime = formattedTime(date)
        return ("위치 확인 중", "\(formattedDate) \(formattedTime)")
    }

    static func titleTexts(date: Date?, locationText: String?) -> (primary: String, secondary: String) {
        let formattedDate = formattedTitleDate(date)
        let formattedTime = formattedTime(date)

        guard let locationText, locationText != "위치 없음" else {
            return (formattedDate, formattedTime)
        }

        return (locationText, "\(formattedDate) \(formattedTime)")
    }

    static func formattedInfoDate(_ date: Date?) -> String {
        guard let date else { return "날짜 없음" }
        return DateFormatter.mediaDetailInfoDate.string(from: date)
    }

    static func mediaTypeText(_ mediaType: PhotoAsset.MediaType) -> String {
        switch mediaType {
        case .image:
            return "사진"
        case .video:
            return "동영상"
        case .unknown:
            return "미디어"
        }
    }
}

private extension DateFormatter {
    static let mediaDetailTitleWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    static let mediaDetailTitleMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter
    }()

    static let mediaDetailTitleYearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }()

    static let mediaDetailInfoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = mediaDetailUses24HourTime ? "yyyy년 M월 d일 EEEE H:mm" : "yyyy년 M월 d일 EEEE a h:mm"
        return formatter
    }()

    static let mediaDetailTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = mediaDetailUses24HourTime ? "H:mm" : "a h:mm"
        return formatter
    }()
}

private let mediaDetailUses24HourTime: Bool = {
    let format = DateFormatter.dateFormat(
        fromTemplate: "j",
        options: 0,
        locale: .autoupdatingCurrent
    ) ?? ""
    return !format.contains("a")
}()

private extension MediaAssetDetails {
    static func formattedTitleDate(_ date: Date?) -> String {
        guard let date else { return "날짜 없음" }

        let calendar = Calendar.autoupdatingCurrent
        let now = Date()

        if let recentBoundary = calendar.date(byAdding: .day, value: -6, to: now) {
            let start = calendar.startOfDay(for: recentBoundary)
            if date >= start {
                return DateFormatter.mediaDetailTitleWeekday.string(from: date)
            }
        }

        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return DateFormatter.mediaDetailTitleMonthDay.string(from: date)
        }

        return DateFormatter.mediaDetailTitleYearMonthDay.string(from: date)
    }

    static func formattedTime(_ date: Date?) -> String {
        guard let date else { return "시간 없음" }
        return DateFormatter.mediaDetailTime.string(from: date)
    }
}
