// ===== SHARED =====
// رَوْح — الجزء المشترك بين التطبيق والودجت
import SwiftUI
import Foundation
import ActivityKit

// MARK: - المحتوى

struct Dhikr: Codable, Identifiable, Hashable {
    let id: String
    let t: String
    let n: Int
    let h: String?
    let f: String?
    let s: String?
    let x: String?
    let q: Bool?
    let qa: [Int]?
    let ha: [Int]?

    var audioURLs: [URL] {
        if let qa, !qa.isEmpty { return qa.compactMap { URL(string: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/\($0).mp3") } }
        if let ha, !ha.isEmpty { return ha.compactMap { URL(string: String(format: "https://www.hisnmuslim.com/audio/ar/ar_7esn_AlMoslem_by_Doors_%03d.mp3", $0)) } }
        return []
    }
}

struct AdhkarCategory: Codable, Identifiable, Hashable {
    let id: String
    let t: String
    let d: String
    let ic: String
    let ca: [Int]
    let items: [Dhikr]
}

struct RefText: Codable, Hashable {
    let t: String
    let r: String
}

struct Occasion: Codable, Hashable {
    let m: Int
    let d: Int
    let t: String
    let ic: String
}

struct DuaRef: Codable, Hashable, Identifiable {
    let ref: String
    let t: String
    var id: String { ref }
}

struct City: Codable, Hashable, Identifiable {
    let id: String
    let n: String
    let lat: Double
    let lng: Double
}

struct RawhData: Codable {
    let cats: [AdhkarCategory]
    let verses: [RefText]
    let hadith: [RefText]
    let occasions: [Occasion]
    let names: [String]
    let duas: [DuaRef]
    let cities: [City]
    let phrases: [String]
}

struct CatDhikr: Identifiable, Hashable {
    let cat: AdhkarCategory
    let dhikr: Dhikr
    var id: String { dhikr.id }
}

enum DB {
    static let data: RawhData = {
        do { return try JSONDecoder().decode(RawhData.self, from: Data(RAWH_JSON.utf8)) }
        catch { fatalError("bad data: \(error)") }
    }()
    static var cats: [AdhkarCategory] { data.cats }
    static func cat(_ id: String) -> AdhkarCategory? { data.cats.first { $0.id == id } }
    static func city(_ id: String) -> City { data.cities.first { $0.id == id } ?? data.cities[0] }
    static var allDhikr: [CatDhikr] { data.cats.flatMap { c in c.items.map { CatDhikr(cat: c, dhikr: $0) } } }
}

// MARK: - أدوات عامة

enum AR {
    static let locale = Locale(identifier: "ar_SA@numbers=arab")
    private static let nf: NumberFormatter = {
        let f = NumberFormatter(); f.locale = locale; f.numberStyle = .decimal; f.usesGroupingSeparator = false; return f
    }()
    static func n(_ v: Int) -> String { nf.string(from: NSNumber(value: v)) ?? "\(v)" }

    static let riyadh = TimeZone(identifier: "Asia/Riyadh") ?? .current
    static var gregorian: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = riyadh; c.locale = locale; return c }
    static var hijri: Calendar { var c = Calendar(identifier: .islamicUmmAlQura); c.timeZone = riyadh; c.locale = locale; return c }

    static func fmt(_ pattern: String, hijri: Bool = false) -> DateFormatter {
        let f = DateFormatter(); f.locale = locale; f.timeZone = riyadh
        f.calendar = hijri ? AR.hijri : AR.gregorian
        f.dateFormat = pattern; return f
    }
    static let timeF = fmt("h:mm a")
    static let dayF = fmt("EEEE، d MMMM")
    static let shortDayF = fmt("d MMMM")
    static let hijriF = fmt("d MMMM y", hijri: true)
    static let keyF: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = riyadh; f.calendar = Calendar(identifier: .gregorian); f.dateFormat = "yyyy-MM-dd"; return f }()

    static func dayKey(_ d: Date = Date()) -> String { keyF.string(from: d) }
    static func hijriString(_ d: Date = Date()) -> String { hijriF.string(from: d) + " هـ" }

    /// تبسيط النص العربي للبحث: حذف التشكيل وتوحيد الألف والياء والتاء المربوطة
    static func normalize(_ s: String) -> String {
        var out = ""
        for u in s.unicodeScalars {
            switch u.value {
            case 0x064B...0x065F, 0x0670, 0x06D6...0x06ED, 0x0640: continue
            case 0x0622, 0x0623, 0x0625, 0x0671: out.unicodeScalars.append("ا")
            case 0x0649: out.unicodeScalars.append("ي")
            case 0x0629: out.unicodeScalars.append("ه")
            case 0x0624: out.unicodeScalars.append("و")
            case 0x0626: out.unicodeScalars.append("ي")
            default: out.unicodeScalars.append(u)
            }
        }
        return out
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

// MARK: - المظهر

enum Skin: String, CaseIterable, Identifiable, Codable {
    case emerald, night, sand
    var id: String { rawValue }
    var name: String {
        switch self { case .emerald: return "زمرّد"; case .night: return "ليل"; case .sand: return "رمل" }
    }
    var scheme: ColorScheme { self == .sand ? .light : .dark }
    var bg: Color {
        switch self { case .emerald: return Color(hex: 0x0A2620); case .night: return Color(hex: 0x0B0F0E); case .sand: return Color(hex: 0xF4ECDD) }
    }
    var bg2: Color {
        switch self { case .emerald: return Color(hex: 0x05170F); case .night: return Color(hex: 0x050807); case .sand: return Color(hex: 0xEADFCB) }
    }
    var card: Color {
        switch self { case .emerald: return Color(hex: 0x10342B); case .night: return Color(hex: 0x141B19); case .sand: return Color(hex: 0xFFFBF3) }
    }
    var card2: Color {
        switch self { case .emerald: return Color(hex: 0x154238); case .night: return Color(hex: 0x1C2522); case .sand: return Color(hex: 0xF1E6D2) }
    }
    var text: Color {
        switch self { case .emerald: return Color(hex: 0xF4ECD8); case .night: return Color(hex: 0xEDE6D6); case .sand: return Color(hex: 0x1D2B26) }
    }
    var sub: Color { text.opacity(0.62) }
    var gold: Color {
        switch self { case .sand: return Color(hex: 0x9A7432); default: return Color(hex: 0xD9BC7F) }
    }
    var goldLight: Color { self == .sand ? Color(hex: 0xC59A4E) : Color(hex: 0xF3DDA6) }
    var green: Color { self == .sand ? Color(hex: 0x1E5B49) : Color(hex: 0x5FC39A) }
    var line: Color { gold.opacity(self == .sand ? 0.28 : 0.22) }
    var onGold: Color { self == .sand ? Color(hex: 0xFFF8EA) : Color(hex: 0x0A2018) }
}


// MARK: - مواقيت الصلاة (طريقة أم القرى)

struct PrayerTimes {
    var fajr: Double, sunrise: Double, dhuhr: Double, asr: Double, maghrib: Double, isha: Double

    static let keys = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]
    static let names = ["fajr": "الفجر", "sunrise": "الشروق", "dhuhr": "الظهر", "asr": "العصر", "maghrib": "المغرب", "isha": "العشاء"]
    static let symbols = ["fajr": "sun.horizon.fill", "sunrise": "sunrise.fill", "dhuhr": "sun.max.fill", "asr": "sun.min.fill", "maghrib": "sunset.fill", "isha": "moon.stars.fill"]

    func hours(_ k: String) -> Double {
        switch k { case "fajr": return fajr; case "sunrise": return sunrise; case "dhuhr": return dhuhr; case "asr": return asr; case "maghrib": return maghrib; default: return isha }
    }

    /// تاريخ الوقت في يوم معيّن
    func date(_ k: String, on day: Date) -> Date {
        let cal = AR.gregorian
        let start = cal.startOfDay(for: day)
        return start.addingTimeInterval(hours(k) * 3600)
    }

    static func compute(for day: Date, city: City) -> PrayerTimes {
        let cal = AR.gregorian
        let c = cal.dateComponents([.year, .month, .day], from: day)
        let lat = city.lat, lng = city.lng, tz = 3.0
        let D2R = Double.pi / 180, R2D = 180 / Double.pi
        func sinD(_ d: Double) -> Double { sin(d * D2R) }
        func cosD(_ d: Double) -> Double { cos(d * D2R) }
        func tanD(_ d: Double) -> Double { tan(d * D2R) }
        func asinD(_ x: Double) -> Double { asin(x) * R2D }
        func acosD(_ x: Double) -> Double { acos(max(-1, min(1, x))) * R2D }
        func atan2D(_ y: Double, _ x: Double) -> Double { atan2(y, x) * R2D }
        func fixA(_ a: Double) -> Double { let r = a - 360 * floor(a / 360); return r < 0 ? r + 360 : r }
        func fixH(_ a: Double) -> Double { let r = a - 24 * floor(a / 24); return r < 0 ? r + 24 : r }
        func julian(_ y0: Int, _ m0: Int, _ d: Int) -> Double {
            var y = Double(y0), m = Double(m0)
            if m <= 2 { y -= 1; m += 12 }
            let A = floor(y / 100), B = 2 - A + floor(A / 4)
            return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + Double(d) + B - 1524.5
        }
        func sunPos(_ jd: Double) -> (decl: Double, eqt: Double) {
            let D = jd - 2451545.0
            let g = fixA(357.529 + 0.98560028 * D), q = fixA(280.459 + 0.98564736 * D)
            let L = fixA(q + 1.915 * sinD(g) + 0.020 * sinD(2 * g)), e = 23.439 - 0.00000036 * D
            let RA = atan2D(cosD(e) * sinD(L), cosD(L)) / 15
            return (asinD(sinD(e) * sinD(L)), q / 15 - fixH(RA))
        }
        let jd = julian(c.year ?? 2026, c.month ?? 1, c.day ?? 1) - lng / (15 * 24)
        func mid(_ t: Double) -> Double { fixH(12 - sunPos(jd + t).eqt) }
        func angleT(_ ang: Double, _ t: Double, _ ccw: Bool) -> Double {
            let dcl = sunPos(jd + t).decl
            let T = acosD((-sinD(ang) - sinD(dcl) * sinD(lat)) / (cosD(dcl) * cosD(lat))) / 15
            return mid(t) + (ccw ? -T : T)
        }
        func asrT(_ t: Double) -> Double {
            let dcl = sunPos(jd + t).decl
            let ang = -atan(1 / (1 + tanD(abs(lat - dcl)))) * R2D
            return angleT(ang, t, false)
        }
        func adj(_ h: Double) -> Double { h + tz - lng / 15 }
        let fajr = adj(angleT(18.5, 5.0 / 24, true))
        let sunrise = adj(angleT(0.833, 6.0 / 24, true))
        let dhuhr = adj(mid(12.0 / 24))
        let asr = adj(asrT(13.0 / 24))
        let maghrib = adj(angleT(0.833, 18.0 / 24, false))
        // أم القرى: العشاء بعد المغرب بساعة ونصف، وساعتين في رمضان
        let ramadan = AR.hijri.component(.month, from: day) == 9
        return PrayerTimes(fajr: fajr, sunrise: sunrise, dhuhr: dhuhr, asr: asr, maghrib: maghrib, isha: maghrib + (ramadan ? 2 : 1.5))
    }

    /// الصلاة القادمة (بدون الشروق)
    static func next(after now: Date, city: City) -> (key: String, date: Date) {
        let today = compute(for: now, city: city)
        for k in ["fajr", "dhuhr", "asr", "maghrib", "isha"] {
            let d = today.date(k, on: now)
            if d > now { return (k, d) }
        }
        let tomorrow = AR.gregorian.date(byAdding: .day, value: 1, to: now) ?? now
        return ("fajr", compute(for: tomorrow, city: city).date("fajr", on: tomorrow))
    }

    /// وِرد الوقت: الصباح من الفجر إلى العصر، والمساء بعده
    static func currentWird(now: Date, city: City) -> String {
        let t = compute(for: now, city: city)
        let h = now.timeIntervalSince(AR.gregorian.startOfDay(for: now)) / 3600
        return (h >= t.fajr && h < t.asr) ? "morning" : "evening"
    }
}

// MARK: - المناسبات الهجرية

struct UpcomingOccasion: Identifiable {
    let id = UUID()
    let occ: Occasion
    let date: Date
    let days: Int
}

enum Occasions {
    static func upcoming(from now: Date = Date()) -> [UpcomingOccasion] {
        let g = AR.gregorian, h = AR.hijri
        var out: [UpcomingOccasion] = []
        let start = g.startOfDay(for: now)
        for i in 0..<390 {
            guard let d = g.date(byAdding: .day, value: i, to: start) else { continue }
            let c = h.dateComponents([.month, .day], from: d)
            for o in DB.data.occasions where o.m == c.month && o.d == c.day {
                if !out.contains(where: { $0.occ == o }) { out.append(UpcomingOccasion(occ: o, date: d, days: i)) }
            }
        }
        return out.sorted { $0.days < $1.days }
    }
}


// MARK: - أشكال إسلامية

/// نجمة ثمانية (مربعان متداخلان) — خاتم سليمان / ربع الحزب
struct EightStar: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), s = min(r.width, r.height) / 2 * 0.72
        for rot in [0.0, Double.pi / 4] {
            var pts: [CGPoint] = []
            for i in 0..<4 {
                let a = rot + Double.pi / 4 + Double(i) * Double.pi / 2
                pts.append(CGPoint(x: c.x + CGFloat(cos(a)) * s * 1.414, y: c.y + CGFloat(sin(a)) * s * 1.414))
            }
            p.move(to: pts[0]); pts.dropFirst().forEach { p.addLine(to: $0) }; p.closeSubpath()
        }
        return p
    }
}

/// نجمة ثمانية مصمتة (للزخرفة الصغيرة)
struct StarBurst: Shape {
    var points = 8
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), R = min(r.width, r.height) / 2, ri = R * 0.42
        for i in 0..<(points * 2) {
            let a = Double(i) * Double.pi / Double(points) - Double.pi / 2
            let rr = i % 2 == 0 ? R : ri
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rr, y: c.y + CGFloat(sin(a)) * rr)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// قوس المحراب
struct ArchShape: Shape {
    var shoulder: CGFloat = 0.42   // نسبة ارتفاع بداية القوس
    func path(in r: CGRect) -> Path {
        var p = Path()
        let top = CGPoint(x: r.midX, y: r.minY)
        let sY = r.minY + r.height * shoulder
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: sY))
        p.addCurve(to: top, control1: CGPoint(x: r.minX, y: sY - r.height * 0.2), control2: CGPoint(x: r.midX - r.width * 0.18, y: r.minY + r.height * 0.1))
        p.addCurve(to: CGPoint(x: r.maxX, y: sY), control1: CGPoint(x: r.midX + r.width * 0.18, y: r.minY + r.height * 0.1), control2: CGPoint(x: r.maxX, y: sY - r.height * 0.2))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        return p
    }
}

/// شبكة زخرفة إسلامية خفيفة للخلفية
struct PatternBackground: View {
    var color: Color
    var opacity: Double = 0.07
    var cell: CGFloat = 64
    var body: some View {
        Canvas { ctx, size in
            let cols = Int(size.width / cell) + 2, rows = Int(size.height / cell) + 2
            for r in 0..<rows {
                for c in 0..<cols {
                    let x = CGFloat(c) * cell + (r % 2 == 0 ? 0 : cell / 2) - cell / 2
                    let y = CGFloat(r) * cell * 0.86 - cell / 2
                    let rect = CGRect(x: x, y: y, width: cell, height: cell)
                    ctx.stroke(EightStar().path(in: rect.insetBy(dx: cell * 0.18, dy: cell * 0.18)), with: .color(color.opacity(opacity)), lineWidth: 0.8)
                    ctx.stroke(Circle().path(in: rect.insetBy(dx: cell * 0.36, dy: cell * 0.36)), with: .color(color.opacity(opacity * 0.7)), lineWidth: 0.6)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// خلفية الشاشات: لون المظهر + الزخرفة + توهّج ذهبي

/// نجمة سداسية منحنية الأضلاع، رؤوسها مدوّرة بيضوية (مفرغة)
struct SixStar: Shape {
    var pull: CGFloat = 0.47     // انحناء الأضلاع للداخل
    var eps: CGFloat = 0.22      // مقدار تدوير الرؤوس
    var bulge: CGFloat = 0.6     // بروز الرأس البيضوي
    func path(in r: CGRect) -> Path {
        var p = Path()
        let R = min(r.width, r.height) / 2
        let c = CGPoint(x: r.midX, y: r.midY)
        func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint { CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t) }
        // جزء من منحنى تربيعي بين t0 و t1
        func sub(_ p0: CGPoint, _ q: CGPoint, _ p1: CGPoint, _ t0: CGFloat, _ t1: CGFloat) -> (CGPoint, CGPoint, CGPoint) {
            let a = lerp(p0, q, t0), b = lerp(q, p1, t0), m = lerp(a, b, t0)
            let t = (t1 - t0) / (1 - t0)
            let a2 = lerp(m, b, t), b2 = lerp(b, p1, t), m2 = lerp(a2, b2, t)
            return (m, a2, m2)
        }
        let tips: [CGPoint] = (0..<6).map { i in
            let a = -Double.pi / 2 + Double(i) * Double.pi / 3
            return CGPoint(x: c.x + CGFloat(cos(a)) * R, y: c.y + CGFloat(sin(a)) * R)
        }
        var segs: [(CGPoint, CGPoint, CGPoint)] = []
        for i in 0..<6 {
            let a = tips[i], b = tips[(i + 1) % 6]
            let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            let q = CGPoint(x: c.x + (mid.x - c.x) * pull, y: c.y + (mid.y - c.y) * pull)
            segs.append(sub(a, q, b, eps, 1 - eps))
        }
        p.move(to: segs[0].0)
        for i in 0..<6 {
            let s = segs[i]
            p.addQuadCurve(to: s.2, control: s.1)
            let tip = tips[(i + 1) % 6], next = segs[(i + 1) % 6].0
            let k = bulge * 0.12
            let ctrl = CGPoint(x: tip.x + (tip.x - c.x) * k, y: tip.y + (tip.y - c.y) * k)
            p.addQuadCurve(to: next, control: ctrl)
        }
        p.closeSubpath()
        return p
    }
}

/// كلمة «رَوْح» مرسومة (من خط Lotus Linotype، محوّلة لمسار)
struct RawhWord: Shape {
    static let ratio: CGFloat = 1.16079   // الارتفاع ÷ العرض
    func path(in r: CGRect) -> Path {
        var p = Path()
        // نملأ العرض ونوسّط عموديًا
        let w = min(r.width, r.height / Self.ratio)
        let h = w * Self.ratio
        // توسيط على حبر الكلمة نفسه (من الفتحة إلى ذيل الحاء)
        let x0 = r.midX - w / 2 - w * 0.01527, y0 = r.midY - h / 2 - w * 0.15840
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x0 + x * w, y: y0 + y * w) }
        func m(_ x: CGFloat, _ y: CGFloat) { p.move(to: pt(x, y)) }
        func l(_ x: CGFloat, _ y: CGFloat) { p.addLine(to: pt(x, y)) }
        func c(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
            p.addCurve(to: pt(x, y), control1: pt(x1, y1), control2: pt(x2, y2))
        }
        func z() { p.closeSubpath() }
        m(0.37684,0.71962); c(0.37122,0.71962,0.36061,0.72037,0.34502,0.72185); c(0.32943,0.72329,0.31652,0.72487,0.30631,0.72658); c(0.27581,0.73100,0.24894,0.73740,0.22567,0.74582)
        c(0.20242,0.75421,0.18082,0.76511,0.16082,0.77851); c(0.13427,0.79676,0.11368,0.81638,0.09906,0.83734); c(0.07785,0.86778,0.06725,0.90044,0.06725,0.93529); c(0.06725,0.96161,0.07339,0.98578,0.08567,1.00781)
        c(0.09798,1.02987,0.11573,1.04846,0.13889,1.06360); c(0.15935,1.07672,0.18487,1.08671,0.21544,1.09354); c(0.24603,1.10035,0.28058,1.10377,0.31906,1.10377); c(0.33929,1.10377,0.36286,1.10267,0.38976,1.10050)
        c(0.41669,1.09830,0.43844,1.09576,0.45502,1.09283); l(0.47257,1.08991); c(0.48258,1.08819,0.48966,1.08734,0.49379,1.08734); c(0.49866,1.08734,0.50110,1.08892,0.50110,1.09207)
        c(0.50110,1.09624,0.49451,1.10197,0.48134,1.10927); c(0.46819,1.11659,0.45078,1.12427,0.42912,1.13231); c(0.40084,1.14302,0.37574,1.15045,0.35380,1.15459); c(0.33188,1.15871,0.30777,1.16079,0.28146,1.16079)
        c(0.20469,1.16079,0.14418,1.14390,0.09994,1.11014); c(0.05573,1.07642,0.03363,1.03032,0.03363,0.97184); c(0.03363,0.91262,0.05079,0.85999,0.08514,0.81395); c(0.10124,0.79228,0.11884,0.77359,0.13795,0.75787)
        c(0.15709,0.74212,0.17921,0.72828,0.20432,0.71635); l(0.20432,0.71378); c(0.20042,0.71281,0.19383,0.71171,0.18456,0.71050); c(0.18288,0.71027,0.17751,0.70955,0.16848,0.70834)
        c(0.14680,0.70492,0.13085,0.70319,0.12064,0.70319); c(0.10895,0.70319,0.09955,0.70448,0.09245,0.70705); c(0.08539,0.70959,0.07857,0.71416,0.07199,0.72074); c(0.06762,0.72487,0.06475,0.72743,0.06339,0.72840)
        c(0.06206,0.72938,0.06042,0.72986,0.05848,0.72986); c(0.05481,0.72986,0.05298,0.72780,0.05298,0.72366); c(0.05298,0.71930,0.05541,0.71267,0.06029,0.70378); c(0.06516,0.69486,0.07101,0.68650,0.07784,0.67869)
        c(0.09662,0.65702,0.11686,0.64617,0.13854,0.64617); c(0.14949,0.64617,0.16775,0.64873,0.19333,0.65384); c(0.22283,0.66020,0.24726,0.66429,0.26660,0.66612); c(0.28598,0.66796,0.31394,0.66886,0.35052,0.66886)
        l(0.38888,0.66846); l(0.40093,0.66846); z(); m(0.55008,0.39692)
        c(0.55008,0.38839,0.55160,0.37944,0.55464,0.37008); c(0.55768,0.36070,0.56163,0.35247,0.56651,0.34540); c(0.57774,0.32982,0.59040,0.32201,0.60452,0.32201); c(0.61622,0.32201,0.62675,0.32804,0.63610,0.34008)
        c(0.64549,0.35213,0.65020,0.36561,0.65020,0.38049); c(0.65020,0.39804,0.64337,0.41315,0.62973,0.42581); c(0.61733,0.43774,0.60417,0.44371,0.59025,0.44371); c(0.57856,0.44371,0.56892,0.43932,0.56137,0.43055)
        c(0.55384,0.42178,0.55008,0.41058,0.55008,0.39692); z(); m(0.56581,0.38447); c(0.56581,0.39106,0.56879,0.39679,0.57476,0.40166)
        c(0.58072,0.40654,0.58783,0.40897,0.59610,0.40897); c(0.60464,0.40897,0.61208,0.40679,0.61844,0.40242); c(0.62572,0.39755,0.62938,0.39254,0.62938,0.38739); c(0.62938,0.38280,0.62682,0.37720,0.62172,0.37061)
        c(0.61438,0.36134,0.60610,0.35669,0.59686,0.35669); c(0.58711,0.35669,0.57906,0.36059,0.57271,0.36839); c(0.56811,0.37400,0.56581,0.37937,0.56581,0.38447); z()
        m(0.67797,0.77413); c(0.67653,0.77413,0.67312,0.77692,0.66774,0.78249); c(0.66286,0.78763,0.65853,0.79113,0.65476,0.79296); c(0.65101,0.79475,0.64634,0.79565,0.64072,0.79565)
        c(0.62512,0.79565,0.61289,0.79091,0.60400,0.78144); c(0.59511,0.77193,0.59066,0.75901,0.59066,0.74266); c(0.59066,0.72977,0.59290,0.71594,0.59739,0.70120); c(0.60191,0.68647,0.60806,0.67277,0.61587,0.66009)
        c(0.62876,0.63889,0.64204,0.62828,0.65569,0.62828); c(0.67055,0.62828,0.68344,0.63938,0.69441,0.66155); c(0.70540,0.68370,0.71090,0.70939,0.71090,0.73863); c(0.71090,0.76620,0.70540,0.79503,0.69441,0.82512)
        c(0.68344,0.85521,0.66835,0.88268,0.64914,0.90752); c(0.63354,0.92775,0.61495,0.94389,0.59335,0.95594); c(0.57179,0.96801,0.55078,0.97406,0.53031,0.97406); c(0.51230,0.97406,0.49208,0.96699,0.46967,0.95284)
        c(0.46015,0.94676,0.45125,0.94016,0.44295,0.93307); c(0.43467,0.92601,0.43055,0.92139,0.43055,0.91921); c(0.43055,0.91800,0.43121,0.91684,0.43254,0.91576); c(0.43390,0.91466,0.43543,0.91412,0.43716,0.91412)
        c(0.43910,0.91412,0.44189,0.91472,0.44552,0.91594); l(0.46201,0.92102); c(0.47565,0.92519,0.48546,0.92788,0.49143,0.92909); c(0.49739,0.93029,0.50426,0.93091,0.51207,0.93091)
        c(0.53104,0.93091,0.54980,0.92614,0.56833,0.91664); c(0.59050,0.90544,0.61049,0.89180,0.62827,0.87570); c(0.64436,0.86135,0.65758,0.84565,0.66791,0.82857); c(0.67828,0.81149,0.68347,0.79711,0.68347,0.78541)
        c(0.68347,0.78225,0.68291,0.77959,0.68183,0.77740); c(0.68074,0.77522,0.67945,0.77413,0.67797,0.77413); z(); m(0.68166,0.73208)
        c(0.68044,0.72038,0.67752,0.71053,0.67288,0.70249); c(0.66484,0.68908,0.65534,0.68237,0.64435,0.68237); c(0.63876,0.68237,0.63384,0.68536,0.62955,0.69132); c(0.62530,0.69729,0.62318,0.70417,0.62318,0.71196)
        c(0.62318,0.72831,0.63461,0.73647,0.65751,0.73647); c(0.66530,0.73647,0.67335,0.73500,0.68166,0.73208); z(); m(0.99668,0.40900)
        c(0.99668,0.41945,0.99376,0.42882,0.98791,0.43713); c(0.98428,0.44248,0.97880,0.44752,0.97148,0.45227); c(0.96418,0.45704,0.95079,0.46406,0.93130,0.47333); l(0.90861,0.48426)
        l(0.88926,0.49338); l(0.87499,0.50034); l(0.86072,0.50765); c(0.85560,0.51034,0.85122,0.51267,0.84756,0.51461)
        l(0.83698,0.52081); l(0.82856,0.52555); l(0.82347,0.52888); c(0.82199,0.52958,0.82076,0.53020,0.81978,0.53069)
        l(0.81797,0.53069); c(0.81747,0.53020,0.81721,0.52970,0.81721,0.52923); c(0.81721,0.52850,0.81747,0.52752,0.81797,0.52631); c(0.81844,0.52558,0.81942,0.52362,0.82089,0.52046)
        c(0.82527,0.51096,0.82885,0.50390,0.83165,0.49929); c(0.83446,0.49466,0.83733,0.49122,0.84025,0.48900); c(0.84684,0.48441,0.87426,0.47064,0.92253,0.44771); l(0.94738,0.43602)
        c(0.97124,0.42483,0.98768,0.41583,0.99668,0.40900); z(); m(0.94772,0.64840); c(0.95310,0.65179,0.95863,0.65696,0.96433,0.66389)
        c(0.97006,0.67084,0.97487,0.67834,0.97877,0.68641); c(0.98488,0.69881,0.98996,0.71410,0.99398,0.73226); c(0.99798,0.75043,1.00000,0.76705,1.00000,0.78214); c(1.00000,0.80749,0.99433,0.83287,0.98298,0.85834)
        c(0.97167,0.88383,0.95602,0.90632,0.93602,0.92582); c(0.92164,0.93993,0.90585,0.95155,0.88866,0.96067); c(0.87149,0.96983,0.85684,0.97442,0.84468,0.97442); c(0.83224,0.97442,0.81310,0.96795,0.78725,0.95506)
        c(0.75875,0.94067,0.74451,0.93164,0.74451,0.92798); c(0.74451,0.92700,0.74505,0.92602,0.74614,0.92506); c(0.74723,0.92408,0.74851,0.92360,0.75000,0.92360); c(0.75195,0.92360,0.75524,0.92433,0.75989,0.92582)
        l(0.77228,0.92874); l(0.78690,0.93237); c(0.79664,0.93483,0.80579,0.93605,0.81433,0.93605); c(0.83698,0.93605,0.86200,0.92623,0.88942,0.90658)
        c(0.91681,0.88696,0.94138,0.86122,0.96310,0.82933); c(0.96965,0.81955,0.97406,0.81259,0.97637,0.80845); c(0.97871,0.80433,0.97988,0.80103,0.97988,0.79857); c(0.97988,0.79494,0.97810,0.78869,0.97456,0.77980)
        c(0.97105,0.77088,0.96649,0.76130,0.96088,0.75109); c(0.95038,0.73183,0.93699,0.71489,0.92070,0.70027); z(); m(0.00000,0.00000)
        return p
    }
}



// MARK: - النشاط المباشر للصلاة (شاشة القفل و Dynamic Island)

struct PrayerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var key: String        // fajr, dhuhr ...
        var name: String       // الفجر ...
        var start: Date        // بداية العدّ
        var date: Date         // وقت الصلاة
    }
    var city: String
}

// MARK: - روابط فتح التطبيق من الودجت و Siri

enum RawhLink {
    static let scheme = "rawh"
    static func category(_ id: String) -> URL { URL(string: "rawh://cat/\(id)")! }
    static let sebha = URL(string: "rawh://sebha")!
    static let prayer = URL(string: "rawh://prayer")!
    static let quran = URL(string: "rawh://quran")!
}

// MARK: - أذكار قصيرة للودجت والتنبيهات

enum DhikrPool {
    struct Item: Hashable {
        let title: String
        let text: String
        let cat: String?
    }

    static let all: [Item] = {
        var out: [Item] = []
        for p in DB.data.phrases { out.append(Item(title: "سبّح", text: p, cat: nil)) }
        for c in DB.cats {
            for d in c.items where d.t.count <= 170 && d.q != true {
                out.append(Item(title: c.t, text: d.t, cat: c.id))
            }
        }
        for h in DB.data.hadith where h.t.count <= 200 { out.append(Item(title: "حديث · \(h.r)", text: h.t, cat: nil)) }
        return out
    }()

    /// ذكر الساعة: يتغيّر كل ساعة، وثابت لكل الأجهزة في نفس الساعة
    static func item(at date: Date) -> Item {
        let hours = Int(date.timeIntervalSince1970 / 3600)
        return all[((hours * 7) % all.count + all.count) % all.count]
    }
}

// MARK: - طور القمر حسب اليوم الهجري (رموز Apple)

enum MoonPhase {
    static func symbol(hijriDay d: Int) -> String {
        switch d {
        case 1, 2, 29, 30: return "moonphase.new.moon"
        case 3...5: return "moonphase.waxing.crescent"
        case 6...9: return "moonphase.first.quarter"
        case 10...13: return "moonphase.waxing.gibbous"
        case 14...16: return "moonphase.full.moon"
        case 17...20: return "moonphase.waning.gibbous"
        case 21...24: return "moonphase.last.quarter"
        default: return "moonphase.waning.crescent"
        }
    }
    static var today: String { symbol(hijriDay: AR.hijri.component(.day, from: Date())) }
}

// MARK: - المحتوى (من حصن المسلم)

let RAWH_JSON = #"""
{"cats":[{"id":"morning","t":"أذكار الصباح","d":"بعد صلاة الفجر","ic":"sun","ca":[28],"items":[{"id":"morning:kursi","t":"اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ ﴿٢٥٥﴾","n":1,"h":"آية الكرسي","f":"من قالها حين يصبح أُجير من الجن حتى يمسي، ومن قالها حين يمسي أُجير منهم حتى يصبح.","s":"سورة البقرة ٢٥٥ · والفضل رواه الحاكم وصححه الألباني","q":true,"qa":[262]},{"id":"morning:ikhlas","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ ﴿١﴾ اللَّهُ الصَّمَدُ ﴿٢﴾ لَمْ يَلِدْ وَلَمْ يُولَدْ ﴿٣﴾ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ﴿٤﴾","n":3,"h":"سورة الإخلاص","f":"من قالها حين يصبح وحين يمسي ثلاث مرات كفته من كل شيء.","s":"رواه أبو داود والترمذي","q":true,"qa":[6222,6223,6224,6225]},{"id":"morning:falaq","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ﴿١﴾ مِنْ شَرِّ مَا خَلَقَ ﴿٢﴾ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ﴿٣﴾ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ﴿٤﴾ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ ﴿٥﴾","n":3,"h":"سورة الفلق","s":"رواه أبو داود والترمذي","q":true,"qa":[6226,6227,6228,6229,6230]},{"id":"morning:nas","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴿١﴾ مَلِكِ النَّاسِ ﴿٢﴾ إِلَٰهِ النَّاسِ ﴿٣﴾ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ﴿٤﴾ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ﴿٥﴾ مِنَ الْجِنَّةِ وَالنَّاسِ ﴿٦﴾","n":3,"h":"سورة الناس","s":"رواه أبو داود والترمذي","q":true,"qa":[6231,6232,6233,6234,6235,6236]},{"id":"morning:mulk","t":"أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ","n":1,"s":"رواه مسلم"},{"id":"morning:bika","t":"اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ","n":1,"s":"رواه الترمذي"},{"id":"morning:sayyid","t":"اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ","n":1,"h":"سيد الاستغفار","f":"من قالها من النهار موقنًا بها فمات من يومه قبل أن يمسي فهو من أهل الجنة.","s":"رواه البخاري"},{"id":"morning:fitra","t":"أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ","n":1,"s":"رواه أحمد"},{"id":"morning:afini","t":"اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ","n":3,"s":"رواه أبو داود"},{"id":"morning:afiya","t":"اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي، وَعَنْ يَمِينِي وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي","n":1,"s":"رواه أبو داود وابن ماجه"},{"id":"morning:yahayy","t":"يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ","n":1,"s":"رواه النسائي في الكبرى والحاكم"},{"id":"morning:bism","t":"بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ","n":3,"f":"من قالها ثلاثًا لم يضره شيء.","s":"رواه أبو داود والترمذي"},{"id":"morning:radit","t":"رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا","n":3,"f":"كان حقًا على الله أن يرضيه يوم القيامة.","s":"رواه أبو داود والترمذي"},{"id":"morning:adad","t":"سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ","n":3,"s":"رواه مسلم"},{"id":"morning:subhan","t":"سُبْحَانَ اللَّهِ وَبِحَمْدِهِ","n":100,"f":"لم يأت أحد يوم القيامة بأفضل مما جاء به، إلا أحد قال مثل ما قال أو زاد عليه.","s":"رواه مسلم"},{"id":"morning:tahlil","t":"لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ","n":100,"f":"كانت له عدل عشر رقاب، وكُتبت له مئة حسنة، ومُحيت عنه مئة سيئة، وكانت له حرزًا من الشيطان يومه ذلك حتى يمسي.","s":"متفق عليه"},{"id":"morning:istighfar","t":"أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ","n":100,"s":"أصله في صحيح مسلم: «فإني أتوب إليه في اليوم مئة مرة»"}]},{"id":"evening","t":"أذكار المساء","d":"بعد صلاة العصر","ic":"moon","ca":[28],"items":[{"id":"evening:kursi","t":"اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ ﴿٢٥٥﴾","n":1,"h":"آية الكرسي","f":"من قالها حين يصبح أُجير من الجن حتى يمسي، ومن قالها حين يمسي أُجير منهم حتى يصبح.","s":"سورة البقرة ٢٥٥ · والفضل رواه الحاكم وصححه الألباني","q":true,"qa":[262]},{"id":"evening:ikhlas","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ ﴿١﴾ اللَّهُ الصَّمَدُ ﴿٢﴾ لَمْ يَلِدْ وَلَمْ يُولَدْ ﴿٣﴾ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ﴿٤﴾","n":3,"h":"سورة الإخلاص","f":"من قالها حين يصبح وحين يمسي ثلاث مرات كفته من كل شيء.","s":"رواه أبو داود والترمذي","q":true,"qa":[6222,6223,6224,6225]},{"id":"evening:falaq","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ﴿١﴾ مِنْ شَرِّ مَا خَلَقَ ﴿٢﴾ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ﴿٣﴾ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ﴿٤﴾ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ ﴿٥﴾","n":3,"h":"سورة الفلق","s":"رواه أبو داود والترمذي","q":true,"qa":[6226,6227,6228,6229,6230]},{"id":"evening:nas","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴿١﴾ مَلِكِ النَّاسِ ﴿٢﴾ إِلَٰهِ النَّاسِ ﴿٣﴾ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ﴿٤﴾ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ﴿٥﴾ مِنَ الْجِنَّةِ وَالنَّاسِ ﴿٦﴾","n":3,"h":"سورة الناس","s":"رواه أبو داود والترمذي","q":true,"qa":[6231,6232,6233,6234,6235,6236]},{"id":"evening:mulk","t":"أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ","n":1,"s":"رواه مسلم"},{"id":"evening:bika","t":"اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ","n":1,"s":"رواه الترمذي"},{"id":"evening:sayyid","t":"اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ","n":1,"h":"سيد الاستغفار","f":"من قالها من الليل وهو موقن بها فمات قبل أن يصبح فهو من أهل الجنة.","s":"رواه البخاري"},{"id":"evening:fitra","t":"أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ","n":1,"s":"رواه أحمد"},{"id":"evening:afini","t":"اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ","n":3,"s":"رواه أبو داود"},{"id":"evening:afiya","t":"اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي، وَعَنْ يَمِينِي وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي","n":1,"s":"رواه أبو داود وابن ماجه"},{"id":"evening:yahayy","t":"يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ","n":1,"s":"رواه النسائي في الكبرى والحاكم"},{"id":"evening:bism","t":"بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ","n":3,"f":"من قالها ثلاثًا لم يضره شيء.","s":"رواه أبو داود والترمذي"},{"id":"evening:radit","t":"رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا","n":3,"f":"كان حقًا على الله أن يرضيه يوم القيامة.","s":"رواه أبو داود والترمذي"},{"id":"evening:tammat","t":"أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ","n":3,"f":"من قالها حين يمسي لم تضره حُمَةٌ تلك الليلة.","s":"رواه مسلم والترمذي"},{"id":"evening:subhan","t":"سُبْحَانَ اللَّهِ وَبِحَمْدِهِ","n":100,"f":"لم يأت أحد يوم القيامة بأفضل مما جاء به، إلا أحد قال مثل ما قال أو زاد عليه.","s":"رواه مسلم"},{"id":"evening:istighfar","t":"أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ","n":100,"s":"أصله في صحيح مسلم: «فإني أتوب إليه في اليوم مئة مرة»"}]},{"id":"prayer","t":"أذكار بعد الصلاة","d":"دبر كل صلاة مكتوبة","ic":"arch","ca":[26],"items":[{"id":"prayer:p1","t":"أَسْتَغْفِرُ اللَّهَ","n":3,"s":"رواه مسلم"},{"id":"prayer:p2","t":"اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ","n":1,"s":"رواه مسلم"},{"id":"prayer:p3","t":"لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ","n":1,"s":"متفق عليه"},{"id":"prayer:p4","t":"سُبْحَانَ اللَّهِ","n":33,"s":"رواه مسلم"},{"id":"prayer:p5","t":"الْحَمْدُ لِلَّهِ","n":33,"s":"رواه مسلم"},{"id":"prayer:p6","t":"اللَّهُ أَكْبَرُ","n":33,"s":"رواه مسلم"},{"id":"prayer:p7","t":"لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ","n":1,"h":"تمام المئة","f":"غُفرت خطاياه وإن كانت مثل زبد البحر.","s":"رواه مسلم"},{"id":"prayer:p8","t":"اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ ﴿٢٥٥﴾","n":1,"h":"آية الكرسي","f":"من قرأها دبر كل صلاة مكتوبة لم يمنعه من دخول الجنة إلا أن يموت.","s":"رواه النسائي في الكبرى","q":true,"qa":[262]},{"id":"prayer:p9","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ ﴿١﴾ اللَّهُ الصَّمَدُ ﴿٢﴾ لَمْ يَلِدْ وَلَمْ يُولَدْ ﴿٣﴾ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ﴿٤﴾\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ﴿١﴾ مِنْ شَرِّ مَا خَلَقَ ﴿٢﴾ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ﴿٣﴾ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ﴿٤﴾ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ ﴿٥﴾\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴿١﴾ مَلِكِ النَّاسِ ﴿٢﴾ إِلَٰهِ النَّاسِ ﴿٣﴾ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ﴿٤﴾ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ﴿٥﴾ مِنَ الْجِنَّةِ وَالنَّاسِ ﴿٦﴾","n":1,"h":"المعوّذات","s":"رواه أبو داود والترمذي","q":true,"qa":[6222,6223,6224,6225,6226,6227,6228,6229,6230,6231,6232,6233,6234,6235,6236]}]},{"id":"sleep","t":"أذكار النوم","d":"قبل أن تنام","ic":"bed","ca":[29],"items":[{"id":"sleep:s1","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ ﴿١﴾ اللَّهُ الصَّمَدُ ﴿٢﴾ لَمْ يَلِدْ وَلَمْ يُولَدْ ﴿٣﴾ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ﴿٤﴾\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ﴿١﴾ مِنْ شَرِّ مَا خَلَقَ ﴿٢﴾ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ﴿٣﴾ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ﴿٤﴾ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ ﴿٥﴾\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴿١﴾ مَلِكِ النَّاسِ ﴿٢﴾ إِلَٰهِ النَّاسِ ﴿٣﴾ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ﴿٤﴾ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ﴿٥﴾ مِنَ الْجِنَّةِ وَالنَّاسِ ﴿٦﴾","n":3,"h":"المعوّذات","s":"رواه البخاري","x":"يجمع كفّيه ثم ينفث فيهما ويقرأ، ثم يمسح بهما ما استطاع من جسده، يبدأ برأسه ووجهه.","q":true,"qa":[6222,6223,6224,6225,6226,6227,6228,6229,6230,6231,6232,6233,6234,6235,6236]},{"id":"sleep:s2","t":"اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ ﴿٢٥٥﴾","n":1,"h":"آية الكرسي","f":"لن يزال عليك من الله حافظ، ولا يقربك شيطان حتى تصبح.","s":"رواه البخاري","q":true,"qa":[262]},{"id":"sleep:s3","t":"آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ، كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ، لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ، وَقَالُوا سَمِعْنَا وَأَطَعْنَا، غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ﴿٢٨٥﴾ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا، لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ، رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا، رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا، رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ، وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا، أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ ﴿٢٨٦﴾","n":1,"h":"خواتيم سورة البقرة","f":"من قرأ بالآيتين من آخر سورة البقرة في ليلة كفتاه.","s":"متفق عليه","q":true,"qa":[292,293]},{"id":"sleep:s4","t":"بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ","n":1,"s":"متفق عليه"},{"id":"sleep:s5","t":"اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ","n":3,"s":"رواه أبو داود والترمذي"},{"id":"sleep:s6","t":"بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا","n":1,"s":"رواه البخاري"},{"id":"sleep:s7","t":"سُبْحَانَ اللَّهِ","n":33,"s":"متفق عليه"},{"id":"sleep:s8","t":"الْحَمْدُ لِلَّهِ","n":33,"s":"متفق عليه"},{"id":"sleep:s9","t":"اللَّهُ أَكْبَرُ","n":34,"f":"هو خير لكما من خادم.","s":"متفق عليه"}]},{"id":"wake","t":"أذكار الاستيقاظ","d":"حين تصحو","ic":"rise","ca":[2],"items":[{"id":"wake:w1","t":"الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ","n":1,"s":"رواه البخاري","ha":[2]},{"id":"wake:w2","t":"لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ، رَبِّ اغْفِرْ لِي","n":1,"h":"لمن استيقظ من الليل","f":"غُفر له، فإن دعا استُجيب له، فإن قام فتوضأ ثم صلى قُبلت صلاته.","s":"رواه البخاري","ha":[2]}]},{"id":"ruqya","t":"الرقية الشرعية","d":"من القرآن والسنة","ic":"shield","ca":[],"items":[{"id":"ruqya:r1","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ﴿١﴾ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ﴿٢﴾ الرَّحْمَٰنِ الرَّحِيمِ ﴿٣﴾ مَالِكِ يَوْمِ الدِّينِ ﴿٤﴾ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ﴿٥﴾ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ﴿٦﴾ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ ﴿٧﴾","n":1,"h":"سورة الفاتحة","f":"قال النبي ﷺ لمن رقى بها: «وما يدريك أنها رقية».","s":"متفق عليه","q":true,"qa":[1,2,3,4,5,6,7]},{"id":"ruqya:r2","t":"اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ، لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ، لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ، مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ، يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ، وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ، وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ، وَلَا يَئُودُهُ حِفْظُهُمَا، وَهُوَ الْعَلِيُّ الْعَظِيمُ ﴿٢٥٥﴾","n":1,"h":"آية الكرسي","s":"سورة البقرة ٢٥٥","q":true,"qa":[262]},{"id":"ruqya:r3","t":"آمَنَ الرَّسُولُ بِمَا أُنْزِلَ إِلَيْهِ مِنْ رَبِّهِ وَالْمُؤْمِنُونَ، كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ، لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِنْ رُسُلِهِ، وَقَالُوا سَمِعْنَا وَأَطَعْنَا، غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ﴿٢٨٥﴾ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا، لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ، رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا، رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا، رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ، وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا، أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ ﴿٢٨٦﴾","n":1,"h":"خواتيم سورة البقرة","s":"سورة البقرة ٢٨٥–٢٨٦","q":true,"qa":[292,293]},{"id":"ruqya:r4","t":"بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ ﴿١﴾ اللَّهُ الصَّمَدُ ﴿٢﴾ لَمْ يَلِدْ وَلَمْ يُولَدْ ﴿٣﴾ وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ ﴿٤﴾\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ﴿١﴾ مِنْ شَرِّ مَا خَلَقَ ﴿٢﴾ وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ ﴿٣﴾ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ﴿٤﴾ وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ ﴿٥﴾\n\nبِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴿١﴾ مَلِكِ النَّاسِ ﴿٢﴾ إِلَٰهِ النَّاسِ ﴿٣﴾ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ﴿٤﴾ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ﴿٥﴾ مِنَ الْجِنَّةِ وَالنَّاسِ ﴿٦﴾","n":3,"h":"المعوّذات","s":"رواه البخاري","q":true,"qa":[6222,6223,6224,6225,6226,6227,6228,6229,6230,6231,6232,6233,6234,6235,6236]},{"id":"ruqya:r5","t":"أَذْهِبِ الْبَأْسَ رَبَّ النَّاسِ، اشْفِ وَأَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمًا","n":1,"s":"متفق عليه"},{"id":"ruqya:r6","t":"بِسْمِ اللَّهِ أَرْقِيكَ، مِنْ كُلِّ شَيْءٍ يُؤْذِيكَ، مِنْ شَرِّ كُلِّ نَفْسٍ أَوْ عَيْنِ حَاسِدٍ، اللَّهُ يَشْفِيكَ، بِسْمِ اللَّهِ أَرْقِيكَ","n":1,"s":"رواه مسلم"},{"id":"ruqya:r7","t":"أَعُوذُ بِاللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ","n":7,"h":"لمن يجد ألمًا","s":"رواه مسلم","x":"يضع يده على موضع الألم ويقول: «بسم الله» ثلاثًا، ثم يقول هذا الدعاء سبع مرات."},{"id":"ruqya:r8","t":"أُعِيذُكَ بِكَلِمَاتِ اللَّهِ التَّامَّةِ، مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ، وَمِنْ كُلِّ عَيْنٍ لَامَّةٍ","n":1,"s":"رواه البخاري","x":"كان النبي ﷺ يعوّذ بها الحسن والحسين."}]},{"id":"distress","t":"عند الهمّ والكرب","d":"حين يضيق الصدر","ic":"heart","ca":[35,36],"items":[{"id":"distress:k1","t":"لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَاوَاتِ وَرَبُّ الْأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ","n":1,"h":"دعاء الكرب","s":"متفق عليه","ha":[36]},{"id":"distress:k2","t":"لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ","n":1,"h":"دعوة ذي النون","f":"لم يدعُ بها رجل مسلم في شيء قط إلا استجاب الله له.","s":"رواه الترمذي","ha":[36]},{"id":"distress:k3","t":"اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ","n":1,"s":"رواه البخاري","ha":[35]},{"id":"distress:k4","t":"اللَّهُ اللَّهُ رَبِّي لَا أُشْرِكُ بِهِ شَيْئًا","n":1,"s":"رواه أبو داود","ha":[36]}]},{"id":"daily","t":"أذكار اليوم والليلة","d":"المنزل والمسجد والطعام والسفر","ic":"path","ca":[],"items":[{"id":"daily:o1","t":"بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ","n":1,"h":"الخروج من المنزل","f":"يقال له: هُديت وكُفيت ووُقيت، وتنحّى عنه الشيطان.","s":"رواه أبو داود والترمذي","ha":[11]},{"id":"daily:o2","t":"اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ","n":1,"h":"دخول المسجد","s":"رواه مسلم","ha":[14]},{"id":"daily:o3","t":"اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ","n":1,"h":"الخروج من المسجد","s":"رواه مسلم","ha":[15]},{"id":"daily:o4","t":"الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا، وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ","n":1,"h":"بعد الطعام","f":"غُفر له ما تقدّم من ذنبه.","s":"رواه أبو داود والترمذي","ha":[71]},{"id":"daily:o5","t":"اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ، وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ","n":1,"h":"ركوب الدابة والسفر","s":"رواه مسلم","x":"مطلع دعاء السفر.","ha":[97]},{"id":"daily:o6","t":"اللَّهُمَّ صَيِّبًا نَافِعًا","n":1,"h":"عند نزول المطر","s":"رواه البخاري","ha":[65]}]}],"verses":[{"t":"أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ","r":"الرعد ٢٨"},{"t":"فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ","r":"البقرة ١٥٢"},{"t":"وَاذْكُرْ رَبَّكَ كَثِيرًا وَسَبِّحْ بِالْعَشِيِّ وَالْإِبْكَارِ","r":"آل عمران ٤١"},{"t":"وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ","r":"البقرة ١٨٦"},{"t":"فَسُبْحَانَ اللَّهِ حِينَ تُمْسُونَ وَحِينَ تُصْبِحُونَ","r":"الروم ١٧"},{"t":"يَا أَيُّهَا الَّذِينَ آمَنُوا اذْكُرُوا اللَّهَ ذِكْرًا كَثِيرًا ﴿٤١﴾ وَسَبِّحُوهُ بُكْرَةً وَأَصِيلًا","r":"الأحزاب ٤١–٤٢"},{"t":"وَلَذِكْرُ اللَّهِ أَكْبَرُ","r":"العنكبوت ٤٥"}],"hadith":[{"t":"كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَنِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ","r":"متفق عليه"},{"t":"أَحَبُّ الْكَلَامِ إِلَى اللَّهِ أَرْبَعٌ: سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ","r":"رواه مسلم"},{"t":"مَثَلُ الَّذِي يَذْكُرُ رَبَّهُ وَالَّذِي لَا يَذْكُرُ رَبَّهُ، مَثَلُ الْحَيِّ وَالْمَيِّتِ","r":"رواه البخاري"},{"t":"لَا يَزَالُ لِسَانُكَ رَطْبًا مِنْ ذِكْرِ اللَّهِ","r":"رواه الترمذي"},{"t":"أَفْضَلُ الذِّكْرِ لَا إِلَهَ إِلَّا اللَّهُ","r":"رواه الترمذي"},{"t":"الطُّهُورُ شَطْرُ الْإِيمَانِ، وَالْحَمْدُ لِلَّهِ تَمْلَأُ الْمِيزَانَ","r":"رواه مسلم"},{"t":"مَنْ قَالَ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، فِي يَوْمٍ مِائَةَ مَرَّةٍ، حُطَّتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ","r":"متفق عليه"}],"occasions":[{"m":9,"d":1,"t":"بداية شهر رمضان","ic":"moon"},{"m":9,"d":21,"t":"العشر الأواخر من رمضان","ic":"moon"},{"m":10,"d":1,"t":"عيد الفطر","ic":"star"},{"m":12,"d":1,"t":"العشر الأوائل من ذي الحجة","ic":"sun"},{"m":12,"d":9,"t":"يوم عرفة","ic":"sun"},{"m":12,"d":10,"t":"عيد الأضحى","ic":"star"},{"m":1,"d":1,"t":"رأس السنة الهجرية","ic":"moon"},{"m":1,"d":10,"t":"يوم عاشوراء","ic":"sun"}],"names":["الله","الرحمن","الرحيم","الملك","القدوس","السلام","المؤمن","المهيمن","العزيز","الجبار","المتكبر","الخالق","البارئ","المصور","الغفار","القهار","الوهاب","الرزاق","الفتاح","العليم","القابض","الباسط","الخافض","الرافع","المعز","المذل","السميع","البصير","الحكم","العدل","اللطيف","الخبير","الحليم","العظيم","الغفور","الشكور","العلي","الكبير","الحفيظ","المقيت","الحسيب","الجليل","الكريم","الرقيب","المجيب","الواسع","الحكيم","الودود","المجيد","الباعث","الشهيد","الحق","الوكيل","القوي","المتين","الولي","الحميد","المحصي","المبدئ","المعيد","المحيي","المميت","الحي","القيوم","الواجد","الماجد","الواحد","الصمد","القادر","المقتدر","المقدم","المؤخر","الأول","الآخر","الظاهر","الباطن","الوالي","المتعالي","البر","التواب","المنتقم","العفو","الرؤوف","مالك الملك","ذو الجلال والإكرام","المقسط","الجامع","الغني","المغني","المانع","الضار","النافع","النور","الهادي","البديع","الباقي","الوارث","الرشيد","الصبور"],"duas":[{"ref":"2:201","t":"حسنة الدنيا والآخرة"},{"ref":"3:8","t":"الثبات على الهداية"},{"ref":"3:147","t":"المغفرة والثبات"},{"ref":"3:193","t":"المغفرة وحسن الخاتمة"},{"ref":"7:23","t":"دعاء آدم عليه السلام"},{"ref":"14:40","t":"إقامة الصلاة في الذرية"},{"ref":"14:41","t":"المغفرة للوالدين"},{"ref":"17:24","t":"الرحمة للوالدين"},{"ref":"18:10","t":"الرحمة والرشد"},{"ref":"20:25-28","t":"شرح الصدر وتيسير الأمر"},{"ref":"20:114","t":"زيادة العلم"},{"ref":"21:87","t":"دعوة ذي النون"},{"ref":"21:89","t":"دعاء زكريا عليه السلام"},{"ref":"23:97-98","t":"الاستعاذة من الشياطين"},{"ref":"23:118","t":"المغفرة والرحمة"},{"ref":"25:65","t":"النجاة من النار"},{"ref":"25:74","t":"صلاح الأزواج والذرية"},{"ref":"27:19","t":"شكر النعمة"},{"ref":"28:24","t":"الافتقار إلى الله"},{"ref":"59:10","t":"لإخوانك المؤمنين"},{"ref":"71:28","t":"دعاء نوح عليه السلام"}],"cities":[{"id":"riyadh","n":"الرياض","lat":24.7136,"lng":46.6753},{"id":"makkah","n":"مكة المكرمة","lat":21.4225,"lng":39.8262},{"id":"madinah","n":"المدينة المنورة","lat":24.4672,"lng":39.6111},{"id":"jeddah","n":"جدة","lat":21.4858,"lng":39.1925},{"id":"dammam","n":"الدمام","lat":26.4207,"lng":50.0888},{"id":"abha","n":"أبها","lat":18.2164,"lng":42.5053},{"id":"tabuk","n":"تبوك","lat":28.3835,"lng":36.5662},{"id":"hail","n":"حائل","lat":27.5114,"lng":41.7208},{"id":"buraydah","n":"بريدة","lat":26.3592,"lng":43.9818},{"id":"jazan","n":"جازان","lat":16.8892,"lng":42.5511}],"phrases":["سُبْحَانَ اللَّهِ","الْحَمْدُ لِلَّهِ","اللَّهُ أَكْبَرُ","لَا إِلَهَ إِلَّا اللَّهُ","أَسْتَغْفِرُ اللَّهَ","سُبْحَانَ اللَّهِ وَبِحَمْدِهِ","لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ","اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ"]}
"""#

// ===== APP =====
// رَوْح — التطبيق
import SwiftUI
import UIKit
import AVFoundation
import CoreLocation
import UserNotifications
import ActivityKit
import AppIntents

// MARK: - الحالة المحفوظة

struct Saved: Codable {
    var skin: Skin = .emerald
    var cityId: String = "riyadh"
    var textScale: Double = 1.0
    var favorites: [String] = []
    var day: String = AR.dayKey()
    var counts: [String: Int] = [:]          // عدّ كل ذكر اليوم
    var history: [String: Int] = [:]         // يوم → عدد التسبيحات والأذكار
    var done: [String: [String]] = [:]       // يوم → الأقسام المكتملة
    var sebhaCount: Int = 0
    var sebhaPhrase: Int = 0
    var sebhaTarget: Int = 33
    var sebhaRounds: Int = 0
    var reminders: [String: Bool] = ["morning": true, "evening": true, "sleep": false, "prayers": false, "fast": false, "white": false, "daily": false]
    var reminderEvery: Int = 3              // ذكر خلال اليوم: كل كم ساعة
    var voiceAlerts: Bool = true            // الجوال ينطق التنبيه
    var introSeen: Bool = false
    var lastSurah: Int = 0
    var lastAyah: Int = 0

    init() {}

    // قراءة متسامحة: أي حقل جديد يأخذ قيمته الافتراضية بدل ما يضيع تقدّمك عند التحديث
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Saved()
        skin = (try? c.decode(Skin.self, forKey: .skin)) ?? d.skin
        cityId = (try? c.decode(String.self, forKey: .cityId)) ?? d.cityId
        textScale = (try? c.decode(Double.self, forKey: .textScale)) ?? d.textScale
        favorites = (try? c.decode([String].self, forKey: .favorites)) ?? d.favorites
        day = (try? c.decode(String.self, forKey: .day)) ?? d.day
        counts = (try? c.decode([String: Int].self, forKey: .counts)) ?? d.counts
        history = (try? c.decode([String: Int].self, forKey: .history)) ?? d.history
        done = (try? c.decode([String: [String]].self, forKey: .done)) ?? d.done
        sebhaCount = (try? c.decode(Int.self, forKey: .sebhaCount)) ?? d.sebhaCount
        sebhaPhrase = (try? c.decode(Int.self, forKey: .sebhaPhrase)) ?? d.sebhaPhrase
        sebhaTarget = (try? c.decode(Int.self, forKey: .sebhaTarget)) ?? d.sebhaTarget
        sebhaRounds = (try? c.decode(Int.self, forKey: .sebhaRounds)) ?? d.sebhaRounds
        var r = (try? c.decode([String: Bool].self, forKey: .reminders)) ?? [:]
        for (k, v) in d.reminders where r[k] == nil { r[k] = v }
        reminders = r
        reminderEvery = (try? c.decode(Int.self, forKey: .reminderEvery)) ?? d.reminderEvery
        voiceAlerts = (try? c.decode(Bool.self, forKey: .voiceAlerts)) ?? d.voiceAlerts
        introSeen = (try? c.decode(Bool.self, forKey: .introSeen)) ?? d.introSeen
        lastSurah = (try? c.decode(Int.self, forKey: .lastSurah)) ?? d.lastSurah
        lastAyah = (try? c.decode(Int.self, forKey: .lastAyah)) ?? d.lastAyah
    }
}

final class AppState: ObservableObject {
    @Published var s: Saved { didSet { persist() } }
    @Published var now = Date()
    private static let key = "rawh.saved.v1"
    private var timer: Timer?

    init() {
        if let d = UserDefaults.standard.data(forKey: Self.key), let v = try? JSONDecoder().decode(Saved.self, from: d) { s = v } else { s = Saved() }
        rollDay()
        timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.now = Date(); self?.rollDay() }
        }
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: Self.key) }
    }

    var skin: Skin { s.skin }
    var city: City { DB.city(s.cityId) }

    func rollDay() {
        let k = AR.dayKey()
        if s.day != k { s.day = k; s.counts = [:] }
    }

    // العدّ
    func count(of d: Dhikr) -> Int { s.counts[d.id] ?? 0 }
    func remaining(_ d: Dhikr) -> Int { max(0, d.n - count(of: d)) }

    /// يرجع true إذا اكتمل الذكر بهذه الضغطة
    @discardableResult
    func tap(_ d: Dhikr, in c: AdhkarCategory) -> Bool {
        rollDay()
        let cur = count(of: d)
        guard cur < d.n else { return false }
        s.counts[d.id] = cur + 1
        s.history[s.day, default: 0] += 1
        if cur + 1 == d.n, progress(c) >= 1 {
            var list = s.done[s.day] ?? []
            if !list.contains(c.id) { list.append(c.id); s.done[s.day] = list }
        }
        return cur + 1 == d.n
    }

    func reset(_ c: AdhkarCategory) { for d in c.items { s.counts[d.id] = 0 } }

    func progress(_ c: AdhkarCategory) -> Double {
        let total = c.items.reduce(0) { $0 + $1.n }
        let doneN = c.items.reduce(0) { $0 + min($1.n, count(of: $1)) }
        return total == 0 ? 0 : Double(doneN) / Double(total)
    }
    func doneCount(_ c: AdhkarCategory) -> Int { c.items.filter { remaining($0) == 0 }.count }

    // المحفوظة
    func isFav(_ d: Dhikr) -> Bool { s.favorites.contains(d.id) }
    func toggleFav(_ d: Dhikr) {
        if let i = s.favorites.firstIndex(of: d.id) { s.favorites.remove(at: i) } else { s.favorites.append(d.id) }
    }

    // السبحة
    func sebhaTap() {
        rollDay()
        s.sebhaCount += 1
        s.history[s.day, default: 0] += 1
        if s.sebhaCount >= s.sebhaTarget { s.sebhaRounds += 1 }
    }

    // الإنجاز
    var todayCount: Int { s.history[AR.dayKey()] ?? 0 }
    var totalCount: Int { s.history.values.reduce(0, +) }
    var streak: Int {
        var n = 0
        var d = Date()
        let cal = AR.gregorian
        // اليوم يُحسب إن اكتمل، وإلا نبدأ من أمس
        if (s.done[AR.dayKey(d)] ?? []).isEmpty { d = cal.date(byAdding: .day, value: -1, to: d) ?? d }
        while let list = s.done[AR.dayKey(d)], list.contains(where: { $0 == "morning" || $0 == "evening" }) {
            n += 1
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return n
    }
}

// MARK: - الصوت

final class AudioPlayer: NSObject, ObservableObject {
    static let shared = AudioPlayer()
    @Published var playingId: String? = nil
    @Published var index: Int = 0
    private var player: AVQueuePlayer?
    private var urls: [URL] = []
    private var endObserver: NSObjectProtocol?

    func toggle(id: String, urls: [URL], from start: Int = 0) {
        if playingId == id { stop(); return }
        play(id: id, urls: urls, from: start)
    }

    func play(id: String, urls: [URL], from start: Int = 0) {
        stop()
        guard !urls.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        self.urls = urls
        let s = min(max(0, start), urls.count - 1)
        let items = urls[s...].map { AVPlayerItem(url: $0) }
        let p = AVQueuePlayer(items: items)
        player = p
        playingId = id
        index = s
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.index += 1
            if self.index >= self.urls.count { self.stop() }
        }
        p.play()
    }

    func stop() {
        player?.pause()
        player?.removeAllItems()
        player = nil
        if let o = endObserver { NotificationCenter.default.removeObserver(o) }
        endObserver = nil
        playingId = nil
    }
}

// MARK: - التذكيرات

struct ReminderItem: Identifiable, Hashable {
    let id: String
    let t: String
    let d: String
}

enum Reminders {
    static let items: [ReminderItem] = [
        ReminderItem(id: "morning", t: "أذكار الصباح", d: "بعد الفجر بعشرين دقيقة، مع ذكر من أذكار الصباح"),
        ReminderItem(id: "evening", t: "أذكار المساء", d: "بعد العصر بربع ساعة، مع ذكر من أذكار المساء"),
        ReminderItem(id: "daily", t: "ذكر خلال اليوم", d: "ذكر قصير أو حديث من ٨ صباحًا إلى ١٠ مساءً"),
        ReminderItem(id: "sleep", t: "أذكار النوم", d: "الساعة ١٠:٣٠ مساءً، مع ذكر من أذكار النوم"),
        ReminderItem(id: "prayers", t: "مواقيت الصلوات الخمس", d: "تنبيه عند دخول كل صلاة"),
        ReminderItem(id: "fast", t: "صيام الاثنين والخميس", d: "تذكير في الليلة السابقة ٩ مساءً"),
        ReminderItem(id: "white", t: "صيام الأيام البيض", d: "تذكير مساء ١٢ من كل شهر هجري")
    ]

    /// أذكار قصيرة تصلح نصًّا كاملًا في الإشعار
    static func shortAdhkar(_ catId: String) -> [Dhikr] {
        let items = DB.cat(catId)?.items ?? []
        let short = items.filter { $0.t.count <= 220 }
        return short.isEmpty ? items : short
    }

    /// مجموعة «ذكر خلال اليوم»: عبارات التسبيح + أذكار قصيرة + أحاديث في فضل الذكر
    static var dailyPool: [(title: String, body: String, cat: String?)] {
        var out: [(title: String, body: String, cat: String?)] = []
        for p in DB.data.phrases { out.append(("ذكر", p, nil)) }
        for c in DB.cats {
            for d in c.items where d.t.count <= 160 && d.q != true { out.append((c.t, d.t, c.id)) }
        }
        for h in DB.data.hadith where h.t.count <= 200 { out.append(("حديث · \(h.r)", h.t, nil)) }
        return out
    }

    // MARK: تجربة التنبيه

    static let testKinds: [(key: String, title: String)] = [
        ("morning", "أذكار الصباح"), ("evening", "أذكار المساء"), ("daily", "ذكر خلال اليوم"),
        ("sleep", "أذكار النوم"), ("asr", "وقت الصلاة"), ("fast", "الصيام")
    ]

    /// يرسل تنبيه تجربة بعد ثوانٍ، بنفس شكل وصوت التنبيه الحقيقي. completion(false) إذا الإشعارات مقفلة
    static func sendTest(_ kind: String, _ s: Saved, after seconds: Double = 5, completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
            guard ok else { DispatchQueue.main.async { completion(false) }; return }
            VoiceAlerts.prepare {
                let c = UNMutableNotificationContent()
                var voice = kind
                switch kind {
                case "morning", "evening", "sleep":
                    let d = shortAdhkar(kind).randomElement()
                    c.title = kind == "morning" ? "أذكار الصباح ☀️" : (kind == "evening" ? "أذكار المساء 🌙" : "أذكار النوم")
                    c.body = d?.t ?? ""
                    if let h = d?.h { c.subtitle = h }
                    c.userInfo = ["cat": kind]
                case "daily":
                    let item = DhikrPool.all.randomElement()
                    c.title = item?.title ?? "ذكر"
                    c.body = item?.text ?? "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ"
                    if let cat = item?.cat { c.userInfo = ["cat": cat] }
                case "fast":
                    c.title = "صيام الاثنين"; c.body = "غدًا يوم الاثنين، يُستحب صيامه"
                default:
                    let city = DB.city(s.cityId)
                    let n = PrayerTimes.next(after: Date(), city: city)
                    voice = n.key
                    c.title = "حان وقت صلاة \(PrayerTimes.names[n.key] ?? "")"; c.body = city.n
                }
                c.sound = VoiceAlerts.sound(voice, enabled: s.voiceAlerts)
                let req = UNNotificationRequest(identifier: "test-\(UUID().uuidString)", content: c,
                                                trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false))
                center.add(req) { _ in DispatchQueue.main.async { completion(true) } }
            }
        }
    }

    static func requestAndSchedule(_ s: Saved) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
            if ok { schedule(s) }
        }
    }

    static func schedule(_ s: Saved) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let on = s.reminders
        let city = DB.city(s.cityId)
        let g = AR.gregorian
        let start = Date()
        let dayIndex = g.ordinality(of: .day, in: .era, for: start) ?? 0

        func content(_ title: String, _ body: String, sub: String? = nil, cat: String? = nil, voice: String? = nil) -> UNMutableNotificationContent {
            let c = UNMutableNotificationContent()
            c.title = title; c.body = body
            c.sound = voice.map { VoiceAlerts.sound($0, enabled: s.voiceAlerts) } ?? .default
            if let sub { c.subtitle = sub }
            if let cat { c.userInfo = ["cat": cat]; c.threadIdentifier = cat }
            return c
        }
        func add(_ id: String, _ c: UNMutableNotificationContent, at date: Date) {
            guard date > Date() else { return }
            let comps = g.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            center.add(UNNotificationRequest(identifier: id, content: c, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
        }
        func pick(_ list: [Dhikr], _ i: Int) -> Dhikr? { list.isEmpty ? nil : list[((i % list.count) + list.count) % list.count] }

        // الحد الأقصى ٦٤ إشعارًا مجدولًا في iOS، ونعيد الجدولة كل مرة تفتح التطبيق
        let morning = shortAdhkar("morning"), evening = shortAdhkar("evening"), sleep = shortAdhkar("sleep")
        for i in 0..<8 {
            guard let day = g.date(byAdding: .day, value: i, to: start) else { continue }
            let t = PrayerTimes.compute(for: day, city: city)
            if on["morning"] == true, let d = pick(morning, dayIndex + i) {
                add("m\(i)", content("أذكار الصباح ☀️", d.t, sub: d.h, cat: "morning", voice: "morning"), at: t.date("fajr", on: day).addingTimeInterval(20 * 60))
            }
            if on["evening"] == true, let d = pick(evening, dayIndex + i) {
                add("e\(i)", content("أذكار المساء 🌙", d.t, sub: d.h, cat: "evening", voice: "evening"), at: t.date("asr", on: day).addingTimeInterval(15 * 60))
            }
            if on["sleep"] == true, let d = pick(sleep, dayIndex + i) {
                add("s\(i)", content("أذكار النوم", d.t, sub: d.h, cat: "sleep", voice: "sleep"), at: g.startOfDay(for: day).addingTimeInterval(22.5 * 3600))
            }
            if on["prayers"] == true && i < 4 {
                for k in ["fajr", "dhuhr", "asr", "maghrib", "isha"] {
                    add("p\(i)\(k)", content("حان وقت صلاة \(PrayerTimes.names[k] ?? "")", city.n, voice: k), at: t.date(k, on: day))
                }
            }
        }
        if on["daily"] == true {
            let pool = dailyPool
            let every = max(2, min(4, s.reminderEvery))
            var n = 0
            for i in 0..<3 {
                guard let day = g.date(byAdding: .day, value: i, to: g.startOfDay(for: start)) else { continue }
                var h = 8
                while h <= 22 {
                    if !pool.isEmpty {
                        let item = pool[(dayIndex * 7 + n * 5) % pool.count]
                        add("d\(i)_\(h)", content(item.title, item.body, cat: item.cat, voice: "daily"), at: day.addingTimeInterval(Double(h) * 3600))
                    }
                    n += 1; h += every
                }
            }
        }
        if on["fast"] == true {
            for (wd, name) in [(1, "الاثنين"), (4, "الخميس")] {
                var c = DateComponents(); c.weekday = wd; c.hour = 21; c.minute = 0
                center.add(UNNotificationRequest(identifier: "fast\(wd)", content: content("صيام \(name)", "غدًا يوم \(name)، يُستحب صيامه", voice: "fast"), trigger: UNCalendarNotificationTrigger(dateMatching: c, repeats: true)))
            }
        }
        if on["white"] == true {
            let h = AR.hijri
            for i in 0..<40 {
                guard let d = g.date(byAdding: .day, value: i, to: g.startOfDay(for: start)) else { continue }
                if h.component(.day, from: d) == 12 {
                    add("white\(i)", content("الأيام البيض", "تبدأ غدًا الأيام البيض: ١٣ و١٤ و١٥", voice: "white"), at: d.addingTimeInterval(21 * 3600))
                }
            }
        }
    }
}

// MARK: - فتح الإشعار على قسمه

final class NotificationRouter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    @Published var openCat: String? = nil
    @Published var tab: Int? = nil

    /// روابط rawh:// من الودجت والنشاط المباشر
    func handle(_ url: URL) {
        guard url.scheme == RawhLink.scheme else { return }
        switch url.host ?? "" {
        case "cat": openCat = url.pathComponents.dropFirst().first
        case "sebha": tab = 2
        case "quran": tab = 1
        default: tab = 0
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let id = response.notification.request.content.userInfo["cat"] as? String {
            DispatchQueue.main.async { self.openCat = id }
        }
        completionHandler()
    }
    // يظهر الإشعار حتى لو كان التطبيق مفتوحًا
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

// MARK: - القبلة

final class QiblaManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0
    @Published var bearing: Double = 0
    @Published var hasHeading = false
    @Published var usingGPS = false
    private let lm = CLLocationManager()
    private var fallback: City

    init(city: City) {
        fallback = city
        super.init()
        lm.delegate = self
        lm.headingFilter = 1
        bearing = Self.qibla(lat: city.lat, lng: city.lng)
    }

    func start() {
        if CLLocationManager.headingAvailable() { lm.startUpdatingHeading() }
        let st = lm.authorizationStatus
        if st == .notDetermined { lm.requestWhenInUseAuthorization() }
        else if st == .authorizedWhenInUse || st == .authorizedAlways { lm.startUpdatingLocation() }
    }
    func stop() { lm.stopUpdatingHeading(); lm.stopUpdatingLocation() }

    static func qibla(lat: Double, lng: Double) -> Double {
        let k = (lat: 21.4225 * Double.pi / 180, lng: 39.8262 * Double.pi / 180)
        let p = (lat: lat * Double.pi / 180, lng: lng * Double.pi / 180)
        let y = sin(k.lng - p.lng)
        let x = cos(p.lat) * tan(k.lat) - sin(p.lat) * cos(k.lng - p.lng)
        let b = atan2(y, x) * 180 / Double.pi
        return b < 0 ? b + 360 : b
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let st = manager.authorizationStatus
        if st == .authorizedWhenInUse || st == .authorizedAlways { manager.startUpdatingLocation() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        let b = Self.qibla(lat: l.coordinate.latitude, lng: l.coordinate.longitude)
        DispatchQueue.main.async { self.bearing = b; self.usingGPS = true }
        manager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        DispatchQueue.main.async { self.heading = h; self.hasHeading = true }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}

// MARK: - عناصر التصميم

struct ScreenBackground: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        let k = app.skin
        ZStack {
            LinearGradient(colors: [k.bg, k.bg2], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [k.gold.opacity(k == .sand ? 0.12 : 0.10), .clear], center: .top, startRadius: 10, endRadius: 420)
            PatternBackground(color: k.gold, opacity: k == .sand ? 0.08 : 0.06)
        }
        .ignoresSafeArea()
    }
}

/// فاصل زخرفي: خط — نجمة — خط
struct Ornament: View {
    @EnvironmentObject var app: AppState
    var width: CGFloat = 140
    var body: some View {
        HStack(spacing: 8) {
            LinearGradient(colors: [.clear, app.skin.gold.opacity(0.7)], startPoint: .leading, endPoint: .trailing).frame(height: 1)
            StarBurst().fill(app.skin.gold).frame(width: 10, height: 10)
            LinearGradient(colors: [app.skin.gold.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing).frame(height: 1)
        }
        .frame(width: width)
    }
}

// MARK: - بطاقات وعناصر

struct Card<C: View>: View {
    @EnvironmentObject var app: AppState
    var padding: CGFloat = 16
    var radius: CGFloat = 22
    var highlight = false
    @ViewBuilder var content: () -> C
    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surface(radius, skin: app.skin, highlight: highlight, tint: highlight ? app.skin.card2 : nil)
    }
}

struct ProgressRing: View {
    var progress: Double
    var color: Color
    var track: Color
    var width: CGFloat = 6
    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: width)
            Circle().trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        }
    }
}

struct GoldButtonStyle: ButtonStyle {
    var skin: Skin
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(skin.onGold)
            .padding(.horizontal, 20).padding(.vertical, 13)
            .goldPill(skin)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var skin: Skin
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(skin.text)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .glassCapsule(skin: skin, fallback: skin.card2.opacity(0.9))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// زر دائري بأيقونة Apple مع حركة ارتداد حقيقية
struct IconButton: View {
    @EnvironmentObject var app: AppState
    var symbol: String
    var size: CGFloat = 40
    var active = false
    var action: () -> Void
    @State private var tick = 0
    var body: some View {
        Button {
            tick += 1; action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(active ? app.skin.gold : app.skin.text)
                .symbolEffect(.bounce, value: tick)
                .frame(width: size, height: size)
                .glassCircle(skin: app.skin, active: active)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: tick)
    }
}

/// أيقونة القسم (أيقونات Apple، والمحراب مرسوم)
struct CategoryIcon: View {
    @EnvironmentObject var app: AppState
    var ic: String
    var size: CGFloat = 46
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(app.skin.gold.opacity(0.14))
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).strokeBorder(app.skin.gold.opacity(0.35), lineWidth: 0.8)
            if ic == "arch" {
                ArchShape().stroke(app.skin.gold, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                    .frame(width: size * 0.42, height: size * 0.5)
            } else {
                Image(systemName: Self.symbol(ic))
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(app.skin.gold)
            }
        }
        .frame(width: size, height: size)
    }
    static func symbol(_ ic: String) -> String {
        switch ic {
        case "sun": return "sun.max.fill"
        case "moon": return "moon.stars.fill"
        case "bed": return "bed.double.fill"
        case "rise": return "sunrise.fill"
        case "shield": return "checkmark.shield.fill"
        case "heart": return "heart.fill"
        case "path": return "point.topleft.down.to.point.bottomright.curvepath.fill"
        case "star": return "sparkles"
        default: return "sparkle"
        }
    }
}

/// الكعبة المشرفة (رسم بسيط)
struct KaabaIcon: View {
    @EnvironmentObject var app: AppState
    var size: CGFloat = 24
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: size * 0.08).fill(Color(hex: 0x111111))
            Rectangle().fill(app.skin.gold).frame(height: size * 0.14).offset(y: size * 0.22)
            RoundedRectangle(cornerRadius: size * 0.08).strokeBorder(app.skin.gold.opacity(0.6), lineWidth: 0.8)
        }
        .frame(width: size, height: size)
    }
}


// MARK: - أيقونة التطبيق (قابلة للتغيير)

enum AppIconChoice: String, CaseIterable, Identifiable {
    case emerald, night, sand, gold, mihrab
    var id: String { rawValue }
    /// اسم الأيقونة البديلة في التطبيق (nil = الأساسية)
    var assetName: String? {
        switch self {
        case .emerald: return nil
        case .night: return "AppIcon-Night"
        case .sand: return "AppIcon-Sand"
        case .gold: return "AppIcon-Gold"
        case .mihrab: return "AppIcon-Mihrab"
        }
    }
    var title: String {
        switch self {
        case .emerald: return "زمرّد"
        case .night: return "ليل"
        case .sand: return "رمل"
        case .gold: return "ذهبي"
        case .mihrab: return "المحراب"
        }
    }
    var colors: (top: Color, bottom: Color, line: Color) {
        switch self {
        case .emerald, .mihrab: return (Color(hex: 0x14473A), Color(hex: 0x062019), Color(hex: 0xE2C88E))
        case .night: return (Color(hex: 0x1A2220), Color(hex: 0x050807), Color(hex: 0xE2C88E))
        case .sand: return (Color(hex: 0xFBF5EA), Color(hex: 0xEADFCB), Color(hex: 0x1E5B49))
        case .gold: return (Color(hex: 0xF1D9A2), Color(hex: 0xB98E45), Color(hex: 0x0B2A22))
        }
    }
    static func current() -> AppIconChoice {
        let n = UIApplication.shared.alternateIconName
        return allCases.first { $0.assetName == n } ?? .emerald
    }
}

/// معاينة الأيقونة داخل التطبيق (نفس رسمة أيقونة الجوال)
struct AppIconPreview: View {
    var choice: AppIconChoice
    var size: CGFloat = 64
    var body: some View {
        let c = choice.colors
        ZStack {
            LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [c.line.opacity(0.22), .clear], center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: size * 0.55)
            if choice == .mihrab {
                ArchShape(shoulder: 0.38).stroke(c.line, style: StrokeStyle(lineWidth: size * 0.025, lineJoin: .round))
                    .frame(width: size * 0.5, height: size * 0.62).offset(y: size * 0.04)
                StarBurst().fill(c.line).frame(width: size * 0.08, height: size * 0.08).offset(y: -size * 0.33)
                Rectangle().fill(c.line).frame(width: size * 0.62, height: size * 0.025).offset(y: size * 0.35)
            } else {
                RoundedRectangle(cornerRadius: size * 0.164, style: .continuous)
                    .stroke(c.line.opacity(0.9), lineWidth: size * 0.0176)
                    .padding(size * 0.129)
                RoundedRectangle(cornerRadius: size * 0.137, style: .continuous)
                    .stroke(c.line.opacity(0.45), lineWidth: size * 0.005)
                    .padding(size * 0.16)
                SixStar()
                    .stroke(c.line, style: StrokeStyle(lineWidth: size * 0.0234, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.654, height: size * 0.654)
                RawhWord()
                    .fill(c.line)
                    .overlay(RawhWord().stroke(c.line, style: StrokeStyle(lineWidth: size * 0.256 * 0.019, lineJoin: .round)))
                    .environment(\.layoutDirection, .leftToRight)   // الرسمة ما تنعكس في الواجهة العربية
                    .frame(width: size * 0.256, height: size * 0.256 * RawhWord.ratio)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
    }
}

/// شعار رَوْح: نجمة سداسية برؤوس بيضوية، وفي وسطها «رَوْح»، داخل إطار ناعم الحواف
struct Emblem: View {
    @EnvironmentObject var app: AppState
    var size: CGFloat = 120
    var animate = false
    @State private var drawn: CGFloat = 0
    var body: some View {
        let t: CGFloat = animate ? drawn : 1
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .trim(from: 0, to: t)
                .stroke(app.skin.gold, style: StrokeStyle(lineWidth: size * 0.022, lineCap: .round))
            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .trim(from: 0, to: t)
                .stroke(app.skin.gold.opacity(0.45), lineWidth: size * 0.007)
                .padding(size * 0.045)
            SixStar()
                .trim(from: 0, to: t)
                .stroke(app.skin.gold, style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.76, height: size * 0.76)
            RawhWord()
                .fill(app.skin.gold)
                .overlay(RawhWord().stroke(app.skin.gold, style: StrokeStyle(lineWidth: size * 0.3 * 0.019, lineJoin: .round)))
                .environment(\.layoutDirection, .leftToRight)   // الرسمة ما تنعكس في الواجهة العربية
                .frame(width: size * 0.3, height: size * 0.3 * RawhWord.ratio)
                .opacity(animate ? Double(drawn) : 1)
                .scaleEffect(animate ? 0.9 + 0.1 * drawn : 1)
        }
        .frame(width: size, height: size)
        .onAppear { if animate { withAnimation(.easeInOut(duration: 1.8)) { drawn = 1 } } }
    }
}

// MARK: - الزجاج السائل (Liquid Glass) — iOS 26، ومظهر البطاقات قبله

extension View {
    /// سطح البطاقات
    @ViewBuilder func surface(_ radius: CGFloat, skin: Skin, highlight: Bool = false, tint: Color? = nil, stroke: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let strong = stroke != nil || highlight
        let edge = stroke ?? (highlight ? skin.gold.opacity(0.7) : skin.line)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint((tint ?? skin.card).opacity(skin == .sand ? 0.6 : 0.5)), in: shape)
                .overlay(shape.strokeBorder(strong ? edge : edge.opacity(0.6), lineWidth: strong ? 1.2 : 0.6))
        } else {
            self.background(shape.fill(tint ?? skin.card))
                .overlay(shape.strokeBorder(edge, lineWidth: strong ? 1.2 : 0.8))
        }
    }
    /// زر دائري
    @ViewBuilder func glassCircle(skin: Skin, active: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(active ? .regular.tint(skin.gold.opacity(0.35)).interactive() : .regular.interactive(), in: Circle())
        } else {
            self.background(Circle().fill(skin.card.opacity(0.95)))
                .overlay(Circle().strokeBorder(active ? skin.gold.opacity(0.7) : skin.line, lineWidth: 0.8))
        }
    }
    /// كبسولة (أزرار وشرائح)
    @ViewBuilder func glassCapsule(skin: Skin, tint: Color? = nil, fallback: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint { self.glassEffect(.regular.tint(tint).interactive(), in: Capsule()) }
            else { self.glassEffect(.regular.interactive(), in: Capsule()) }
        } else {
            self.background(Capsule().fill(fallback ?? tint ?? skin.card))
                .overlay(Capsule().strokeBorder(skin.line, lineWidth: 0.8))
        }
    }
    /// الزر الذهبي
    @ViewBuilder func goldPill(_ skin: Skin) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(skin.gold).interactive(), in: Capsule())
        } else {
            self.background(Capsule().fill(LinearGradient(colors: [skin.goldLight, skin.gold], startPoint: .top, endPoint: .bottom)))
        }
    }
    /// حبة السبحة الكبيرة
    @ViewBuilder func beadSurface(_ skin: Skin) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(skin.card2.opacity(0.45)).interactive(), in: Circle())
                .overlay(Circle().strokeBorder(skin.gold.opacity(0.45), lineWidth: 1))
        } else {
            self.background(Circle().fill(RadialGradient(colors: [skin.card2, skin.card], center: .topLeading, startRadius: 10, endRadius: 200)))
                .overlay(Circle().strokeBorder(skin.gold.opacity(0.5), lineWidth: 1.2))
        }
    }
    /// شريط التبويبات يصغر عند التمرير (iOS 26)
    @ViewBuilder func minimizingTabBar() -> some View {
        if #available(iOS 26.0, *) { self.tabBarMinimizeBehavior(.onScrollDown) } else { self }
    }
}

// MARK: - حركات أيقونات Apple حسب إصدار iOS

extension View {
    /// تنفّس (iOS 18) أو نبض (iOS 17)
    @ViewBuilder func breathing(_ active: Bool = true) -> some View {
        if #available(iOS 18.0, *) { self.symbolEffect(.breathe, isActive: active) }
        else { self.symbolEffect(.pulse, isActive: active) }
    }
    /// اهتزاز (iOS 18) أو ارتداد (iOS 17)
    @ViewBuilder func wiggle<V: Equatable>(on value: V) -> some View {
        if #available(iOS 18.0, *) { self.symbolEffect(.wiggle, value: value) }
        else { self.symbolEffect(.bounce, value: value) }
    }
    /// دوران (iOS 18) أو ارتداد (iOS 17)
    @ViewBuilder func spin<V: Equatable>(on value: V) -> some View {
        if #available(iOS 18.0, *) { self.symbolEffect(.rotate, value: value) }
        else { self.symbolEffect(.bounce, value: value) }
    }
    func rawhText(_ size: CGFloat, _ weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: size, weight: weight))
    }
}

struct SectionTitle: View {
    @EnvironmentObject var app: AppState
    var title: String
    var trailing: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 8) {
                StarBurst().fill(app.skin.gold).frame(width: 9, height: 9)
                Text(title).rawhText(19, .bold).foregroundStyle(app.skin.text)
            }
            Spacer()
            if let trailing { Text(trailing).rawhText(13).foregroundStyle(app.skin.sub) }
        }
        .padding(.top, 8)
    }
}


// MARK: - لمسات فنية

/// زخرفة الزوايا: زاوية ذهبية ونقطة في كل ركن
struct CornerOrnaments: View {
    var color: Color
    var inset: CGFloat = 10
    var arm: CGFloat = 16
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            Path { p in
                for (x, y, sx, sy) in [(inset, inset, 1.0, 1.0), (w - inset, inset, -1.0, 1.0), (inset, h - inset, 1.0, -1.0), (w - inset, h - inset, -1.0, -1.0)] {
                    p.move(to: CGPoint(x: x, y: y + arm * CGFloat(sy)))
                    p.addLine(to: CGPoint(x: x, y: y))
                    p.addLine(to: CGPoint(x: x + arm * CGFloat(sx), y: y))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            ForEach(0..<4, id: \.self) { i in
                let x: CGFloat = i % 2 == 0 ? inset + 5 : w - inset - 5
                let y: CGFloat = i < 2 ? inset + 5 : h - inset - 5
                Circle().fill(color).frame(width: 3, height: 3).position(x: x, y: y)
            }
        }
        .allowsHitTesting(false)
    }
}

/// عنوان يلمع بالذهب كل لحظات
struct ShimmerText: View {
    var text: String
    var size: CGFloat
    var base: Color
    var shine: Color
    @State private var phase: CGFloat = -1
    var body: some View {
        Text(text)
            .rawhText(size, .bold)
            .foregroundStyle(base)
            .overlay(
                GeometryReader { g in
                    LinearGradient(colors: [.clear, shine.opacity(0.9), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: g.size.width * 0.6)
                        .offset(x: phase * g.size.width * 1.6)
                }
                .mask(Text(text).rawhText(size, .bold))
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).delay(0.6).repeatForever(autoreverses: false)) { phase = 1 }
            }
    }
}

/// مسار الشمس اليوم: من الشروق إلى المغرب، والشمس في مكانها الآن
struct SunPathView: View {
    @EnvironmentObject var app: AppState
    var times: PrayerTimes
    var now: Date

    private func frac(_ h: Double) -> Double { (h - times.sunrise) / max(0.1, times.maghrib - times.sunrise) }

    var body: some View {
        let start = AR.gregorian.startOfDay(for: now)
        let h = now.timeIntervalSince(start) / 3600
        let f = frac(h)
        let day = f >= 0 && f <= 1
        GeometryReader { g in
            let w = g.size.width, H = g.size.height
            let pad: CGFloat = 18
            // الشمس تشرق من اليمين وتغرب في اليسار (اتجاه القراءة العربي)
            let point: (Double) -> CGPoint = { t in
                let a = Double.pi * t
                return CGPoint(x: w - pad - CGFloat(t) * (w - 2 * pad), y: H - 22 - CGFloat(sin(a)) * (H - 40))
            }
            ZStack {
                // الأفق
                Rectangle().fill(app.skin.gold.opacity(0.25)).frame(height: 0.8).position(x: w / 2, y: H - 22)
                // المسار المنقّط
                Path { p in
                    p.move(to: point(0))
                    for i in 1...60 { p.addLine(to: point(Double(i) / 60)) }
                }
                .stroke(app.skin.gold.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, dash: [3, 5]))
                // الجزء المقطوع من النهار
                if day {
                    Path { p in
                        p.move(to: point(0))
                        let n = max(1, Int(f * 60))
                        for i in 1...n { p.addLine(to: point(min(f, Double(i) / 60))) }
                    }
                    .stroke(LinearGradient(colors: [app.skin.gold.opacity(0.3), app.skin.goldLight], startPoint: .trailing, endPoint: .leading), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                }
                // الظهر والعصر على المسار
                ForEach(["dhuhr", "asr"], id: \.self) { k in
                    let t = frac(times.hours(k))
                    if t > 0 && t < 1 {
                        let pt = point(t)
                        Circle().fill(app.skin.card).overlay(Circle().strokeBorder(app.skin.gold, lineWidth: 1.2)).frame(width: 9, height: 9).position(pt)
                        Text(PrayerTimes.names[k] ?? "").rawhText(10.5, .medium).foregroundStyle(app.skin.sub).position(x: pt.x, y: pt.y - 14)
                    }
                }
                // الشروق والمغرب
                Text("الشروق \(AR.timeF.string(from: times.date("sunrise", on: now)))").rawhText(10.5).foregroundStyle(app.skin.sub)
                    .position(x: w - pad - 20, y: H - 8)
                Text("المغرب \(AR.timeF.string(from: times.date("maghrib", on: now)))").rawhText(10.5).foregroundStyle(app.skin.sub)
                    .position(x: pad + 20, y: H - 8)
                // الشمس أو القمر
                if day {
                    let s = point(f)
                    Circle().fill(RadialGradient(colors: [app.skin.goldLight.opacity(0.7), .clear], center: .center, startRadius: 2, endRadius: 26))
                        .frame(width: 52, height: 52).position(s)
                    Image(systemName: "sun.max.fill").font(.system(size: 18)).foregroundStyle(app.skin.goldLight)
                        .symbolEffect(.pulse)
                        .position(s)
                } else {
                    Image(systemName: MoonPhase.today).font(.system(size: 20)).foregroundStyle(app.skin.goldLight)
                        .position(x: w / 2, y: H * 0.42)
                    Text("الليل · \(AR.hijriString(now))").rawhText(11).foregroundStyle(app.skin.sub).position(x: w / 2, y: H * 0.42 + 22)
                }
            }
        }
        .frame(height: 120)
    }
}

/// احتفال بإتمام الوِرد: نجوم ذهبية تنطلق من المركز
struct CelebrationBurst: View {
    var trigger: Int
    var color: Color
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                let a = Double(i) / 14 * 2 * Double.pi
                let r: CGFloat = 90 + CGFloat(i % 3) * 30
                SixStar().fill(color)
                    .frame(width: CGFloat(8 + (i % 3) * 4), height: CGFloat(8 + (i % 3) * 4))
                    .offset(x: go ? CGFloat(cos(a)) * r : 0, y: go ? CGFloat(sin(a)) * r : 0)
                    .rotationEffect(.degrees(go ? 180 : 0))
                    .opacity(go ? 0 : 1)
                    .scaleEffect(go ? 0.4 : 1.1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            go = false
            withAnimation(.easeOut(duration: 1.1)) { go = true }
        }
        .opacity(trigger == 0 ? 0 : 1)
    }
}

/// شاشة الافتتاح: النجمة تُرسم ثم يظهر الاسم
struct SplashView: View {
    @EnvironmentObject var app: AppState
    var done: () -> Void
    @State private var show = false
    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 18) {
                Emblem(size: 150, animate: true)
                Text("رَوْح").rawhText(40, .bold).foregroundStyle(app.skin.text)
                    .opacity(show ? 1 : 0).offset(y: show ? 0 : 8)
                Text("ذِكرٌ تطمئن به القلوب").rawhText(14).foregroundStyle(app.skin.gold)
                    .opacity(show ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.9)) { show = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) { done() }
        }
    }
}

/// تأثير ظهور البطاقات أثناء التمرير
extension View {
    func scrollReveal() -> some View {
        self.scrollTransition(.animated(.spring(response: 0.45, dampingFraction: 0.85))) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.55)
                .scaleEffect(phase.isIdentity ? 1 : 0.95)
                .blur(radius: phase.isIdentity ? 0 : 1.5)
        }
    }
}


// MARK: - الرئيسية

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var showSettings = false
    @State private var showSearch = false
    @State private var showCity = false
    @State private var reader: AdhkarCategory? = nil
    @State private var focus = false
    @State private var liveOn = PrayerLive.isRunning
    @State private var liveTick = 0

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        wirdCard
                        prayerCard
                        verseCard
                        SectionTitle(title: "الأذكار", trailing: "\(AR.n(DB.cats.count)) أقسام")
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(DB.cats) { c in
                                Button { reader = c; focus = false } label: { CategoryTile(cat: c) }
                                    .buttonStyle(PressScale())
                                    .scrollReveal()
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView().environmentObject(app) }
            .sheet(isPresented: $showSearch) { SearchView().environmentObject(app) }
            .fullScreenCover(item: $reader) { c in ReaderView(cat: c, startFocus: focus).environmentObject(app) }
            .confirmationDialog("اختر مدينتك", isPresented: $showCity, titleVisibility: .visible) {
                ForEach(DB.data.cities) { c in Button(c.n) { app.s.cityId = c.id; Reminders.schedule(app.s) } }
            }
        }
    }

    private var greeting: String {
        let h = AR.gregorian.component(.hour, from: app.now)
        if h < 4 { return "ليلة طيبة" }
        if h < 12 { return "صباح الخير" }
        if h < 17 { return "طاب يومك" }
        return "مساء الخير"
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting).rawhText(14, .medium).foregroundStyle(app.skin.gold)
                ShimmerText(text: "رَوْح", size: 34, base: app.skin.text, shine: app.skin.goldLight)
                Text("ذِكرٌ تطمئن به القلوب").rawhText(13).foregroundStyle(app.skin.sub)
            }
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: MoonPhase.today).font(.system(size: 20)).foregroundStyle(app.skin.goldLight)
                    .symbolRenderingMode(.hierarchical)
                Text(AR.n(AR.hijri.component(.day, from: app.now))).rawhText(10, .semibold).foregroundStyle(app.skin.sub)
            }
            .padding(.horizontal, 4)
            IconButton(symbol: "magnifyingglass") { showSearch = true }
            IconButton(symbol: "slider.horizontal.3") { showSettings = true }
        }
        .padding(.top, 8)
    }

    // وِرد الوقت داخل قوس محراب
    private var wirdCard: some View {
        let id = PrayerTimes.currentWird(now: app.now, city: app.city)
        let cat = DB.cat(id) ?? DB.cats[0]
        let p = app.progress(cat)
        return ZStack(alignment: .topLeading) {
            Color.clear
            ArchShape(shoulder: 0.3)
                .stroke(app.skin.gold.opacity(0.18), lineWidth: 1)
                .frame(width: 170, height: 230)
                .offset(x: -30, y: 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
            EightStar().stroke(app.skin.gold.opacity(0.12), lineWidth: 1)
                .frame(width: 150, height: 150)
                .offset(x: 40, y: -40)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar").foregroundStyle(app.skin.gold)
                    Text(AR.hijriString(app.now)).rawhText(13, .semibold).foregroundStyle(app.skin.gold)
                    Text("·").foregroundStyle(app.skin.sub)
                    Text(AR.dayF.string(from: app.now)).rawhText(13).foregroundStyle(app.skin.sub)
                }
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("وِردك الآن").rawhText(13, .medium).foregroundStyle(app.skin.sub)
                        Text(cat.t).rawhText(30, .bold).foregroundStyle(app.skin.text)
                        Text(p >= 1 ? "أتممت الوِرد، تقبّل الله منك" : "\(cat.d) · بقي \(AR.n(cat.items.count - app.doneCount(cat))) من \(AR.n(cat.items.count))")
                            .rawhText(13).foregroundStyle(app.skin.sub)
                    }
                    Spacer()
                    ZStack {
                        ProgressRing(progress: p, color: app.skin.gold, track: app.skin.gold.opacity(0.15), width: 7)
                        Image(systemName: p >= 1 ? "checkmark" : CategoryIcon.symbol(cat.ic))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(app.skin.gold)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .frame(width: 70, height: 70)
                }
                HStack(spacing: 10) {
                    Button { focus = false; reader = cat } label: {
                        Label(p > 0 && p < 1 ? "أكمل الوِرد" : "ابدأ الوِرد", systemImage: "chevron.left")
                    }
                    .buttonStyle(GoldButtonStyle(skin: app.skin))
                    Button { focus = true; reader = cat } label: {
                        Label("وضع الخلوة", systemImage: "smallcircle.filled.circle")
                    }
                    .buttonStyle(GhostButtonStyle(skin: app.skin))
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .surface(28, skin: app.skin, tint: app.skin.card2, stroke: app.skin.gold.opacity(0.4))
        .overlay(CornerOrnaments(color: app.skin.gold.opacity(0.55), inset: 12, arm: 18))
    }

    private var prayerCard: some View {
        let t = PrayerTimes.compute(for: app.now, city: app.city)
        let nx = PrayerTimes.next(after: app.now, city: app.city)
        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("الصلاة القادمة").rawhText(12).foregroundStyle(app.skin.sub)
                        HStack(spacing: 6) {
                            Text(PrayerTimes.names[nx.key] ?? "").rawhText(20, .bold).foregroundStyle(app.skin.text)
                            Text(Self.left(nx.date.timeIntervalSince(app.now))).rawhText(14, .semibold).foregroundStyle(app.skin.gold)
                        }
                    }
                    Spacer()
                    Button { showCity = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(app.city.n).rawhText(13, .semibold)
                        }
                        .foregroundStyle(app.skin.gold)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .glassCapsule(skin: app.skin, tint: app.skin.gold.opacity(0.25), fallback: app.skin.gold.opacity(0.12))
                    }
                    .buttonStyle(.plain)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(PrayerTimes.keys, id: \.self) { k in
                        let isNext = k == nx.key
                        VStack(spacing: 6) {
                            Image(systemName: PrayerTimes.symbols[k] ?? "sun.max")
                                .font(.system(size: 19, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(isNext ? app.skin.gold : app.skin.sub)
                                .breathing(isNext)
                                .frame(height: 22)
                            Text(PrayerTimes.names[k] ?? "").rawhText(12.5, .medium).foregroundStyle(isNext ? app.skin.gold : app.skin.sub)
                            Text(AR.timeF.string(from: t.date(k, on: app.now))).rawhText(14.5, .bold).foregroundStyle(app.skin.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(isNext ? app.skin.gold.opacity(0.13) : Color.clear))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(isNext ? app.skin.gold.opacity(0.6) : Color.clear, lineWidth: 1))
                    }
                }
                SunPathView(times: t, now: app.now)
                HStack {
                    Text("بتوقيت أم القرى").rawhText(11).foregroundStyle(app.skin.sub.opacity(0.8))
                    Spacer()
                    Button {
                        liveTick += 1
                        if liveOn { PrayerLive.stop(); liveOn = false } else { PrayerLive.start(city: app.city); liveOn = true }
                    } label: {
                        Label(liveOn ? "على شاشة القفل" : "تابع على شاشة القفل", systemImage: liveOn ? "lock.iphone" : "iphone.badge.play")
                            .rawhText(12, .semibold)
                            .foregroundStyle(liveOn ? app.skin.onGold : app.skin.gold)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .glassCapsule(skin: app.skin, tint: liveOn ? app.skin.gold : nil, fallback: liveOn ? app.skin.gold : app.skin.gold.opacity(0.12))
                            .symbolEffect(.bounce, value: liveTick)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.success, trigger: liveTick)
                    .opacity(PrayerLive.enabled ? 1 : 0.4)
                    .disabled(!PrayerLive.enabled)
                }
            }
        }
    }

    static func left(_ secs: TimeInterval) -> String {
        let m = max(0, Int(secs / 60))
        let h = m / 60, mm = m % 60
        if h > 0 { return "بعد \(AR.n(h)) س \(AR.n(mm)) د" }
        return "بعد \(AR.n(mm)) دقيقة"
    }

    private var verseCard: some View {
        let list = DB.data.verses
        let day = AR.gregorian.ordinality(of: .day, in: .year, for: app.now) ?? 0
        let v = list[day % max(1, list.count)]
        return Card(highlight: false) {
            VStack(spacing: 10) {
                Ornament()
                Text("﴿ \(v.t) ﴾")
                    .rawhText(21 * app.s.textScale, .medium)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .foregroundStyle(app.skin.text)
                    .frame(maxWidth: .infinity)
                Text(v.r).rawhText(12).foregroundStyle(app.skin.gold)
            }
            .padding(.vertical, 6)
        }
        .overlay(CornerOrnaments(color: app.skin.gold.opacity(0.45)))
    }
}

struct CategoryTile: View {
    @EnvironmentObject var app: AppState
    var cat: AdhkarCategory
    var body: some View {
        let p = app.progress(cat)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryIcon(ic: cat.ic, size: 42)
                Spacer()
                if p >= 1 {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(app.skin.green).font(.system(size: 18))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            Text(cat.t).rawhText(16, .bold).foregroundStyle(app.skin.text).lineLimit(1).minimumScaleFactor(0.8)
            Text(cat.d).rawhText(12).foregroundStyle(app.skin.sub).lineLimit(1)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(app.skin.gold.opacity(0.14))
                    Capsule().fill(app.skin.gold).frame(width: max(4, g.size.width * p))
                }
            }
            .frame(height: 4)
            .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(14)
        .surface(20, skin: app.skin)
    }
}


// MARK: - قارئ الأذكار

struct ReaderView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audio = AudioPlayer.shared
    let cat: AdhkarCategory
    var startFocus = false
    @State private var focus = false
    @State private var page: String? = nil
    @State private var completed = 0
    @State private var resetTick = 0
    @State private var share: Dhikr? = nil
    @State private var confirmReset = false
    @State private var celebrate = 0

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 0) {
                topBar
                if focus { focusMode } else { list }
            }
            CelebrationBurst(trigger: celebrate, color: app.skin.goldLight)
        }
        .onAppear { focus = startFocus; page = firstOpen()?.id ?? cat.items.first?.id }
        .onDisappear { AudioPlayer.shared.stop() }
        .sheet(item: $share) { d in ShareSheet(dhikr: d, cat: cat).environmentObject(app).presentationDetents([.large]) }
        .sensoryFeedback(.success, trigger: completed)
        .confirmationDialog("تصفير عدّاد هذا القسم؟", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("تصفير", role: .destructive) { resetTick += 1; withAnimation { app.reset(cat) }; page = cat.items.first?.id }
            Button("إلغاء", role: .cancel) {}
        }
        .preferredColorScheme(app.skin.scheme)
    }

    private func firstOpen() -> Dhikr? { cat.items.first { app.remaining($0) > 0 } }

    private var topBar: some View {
        let p = app.progress(cat)
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                IconButton(symbol: "chevron.right") { dismiss() }
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.t).rawhText(19, .bold).foregroundStyle(app.skin.text)
                    Text("\(AR.n(app.doneCount(cat))) من \(AR.n(cat.items.count)) · \(cat.d)").rawhText(12).foregroundStyle(app.skin.sub)
                }
                Spacer()
                if !cat.ca.isEmpty {
                    let pid = "cat:" + cat.id
                    IconButton(symbol: audio.playingId == pid ? "stop.fill" : "play.fill", active: audio.playingId == pid) {
                        let urls = cat.ca.compactMap { URL(string: String(format: "https://www.hisnmuslim.com/audio/ar/ar_7esn_AlMoslem_by_Doors_%03d.mp3", $0)) }
                        audio.toggle(id: pid, urls: urls)
                    }
                }
                IconButton(symbol: focus ? "list.bullet" : "smallcircle.filled.circle", active: focus) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { focus.toggle() }
                }
                Button { confirmReset = true } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(app.skin.text)
                        .spin(on: resetTick)
                        .frame(width: 40, height: 40)
                        .glassCircle(skin: app.skin)
                }
                .buttonStyle(.plain)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(app.skin.gold.opacity(0.14))
                    Capsule().fill(LinearGradient(colors: [app.skin.goldLight, app.skin.gold], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, g.size.width * p))
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: p)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private func tap(_ d: Dhikr, proxy: ScrollViewProxy?) {
        let finished = app.tap(d, in: cat)
        if finished {
            completed += 1
            if app.progress(cat) >= 1 { celebrate += 1 }
            if let nextD = cat.items.first(where: { app.remaining($0) > 0 }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        page = nextD.id
                        proxy?.scrollTo(nextD.id, anchor: .top)
                    }
                }
            }
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(cat.items) { d in
                        DhikrCard(dhikr: d, cat: cat, onTap: { tap(d, proxy: proxy) }, onShare: { share = d })
                            .id(d.id)
                            .scrollReveal()
                    }
                    if app.progress(cat) >= 1 {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 44)).foregroundStyle(app.skin.gold)
                                .symbolEffect(.bounce, value: completed)
                            Text("أتممت \(cat.t)").rawhText(20, .bold).foregroundStyle(app.skin.text)
                            Text("تقبّل الله منك، وجعلها في ميزان حسناتك").rawhText(14).foregroundStyle(app.skin.sub)
                        }
                        .padding(.vertical, 30)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
            .onAppear {
                if let first = firstOpen(), first.id != cat.items.first?.id {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { proxy.scrollTo(first.id, anchor: .top) }
                }
            }
        }
    }

    // وضع الخلوة: ذكر واحد كبير في كل صفحة، الضغط في أي مكان يعدّ
    private var focusMode: some View {
        TabView(selection: Binding(get: { page ?? cat.items.first?.id ?? "" }, set: { page = $0 })) {
            ForEach(cat.items) { d in
                FocusPage(dhikr: d, cat: cat) { tap(d, proxy: nil) }
                    .tag(d.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

struct DhikrCard: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var audio = AudioPlayer.shared
    let dhikr: Dhikr
    let cat: AdhkarCategory
    var onTap: () -> Void
    var onShare: () -> Void
    @State private var tick = 0
    @State private var favTick = 0
    @State private var copied = false

    var body: some View {
        let rem = app.remaining(dhikr)
        let done = rem == 0
        let cnt = app.count(of: dhikr)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if dhikr.q == true {
                    Text("قرآن").rawhText(11, .bold).foregroundStyle(app.skin.onGold)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(app.skin.gold))
                }
                if let h = dhikr.h { Text(h).rawhText(13, .semibold).foregroundStyle(app.skin.gold) }
                Spacer()
                if dhikr.n > 1 {
                    Text("\(AR.n(dhikr.n)) مرات").rawhText(12, .medium).foregroundStyle(app.skin.sub)
                }
            }
            if let x = dhikr.x {
                Text(x).rawhText(13).italic().foregroundStyle(app.skin.sub).lineSpacing(4)
            }
            Text(dhikr.t)
                .rawhText(21 * app.s.textScale, .regular)
                .lineSpacing(11 * app.s.textScale)
                .foregroundStyle(done ? app.skin.text.opacity(0.55) : app.skin.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let f = dhikr.f {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles").font(.system(size: 13)).foregroundStyle(app.skin.gold).padding(.top, 2)
                    Text(f).rawhText(13.5).foregroundStyle(app.skin.gold).lineSpacing(4)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(app.skin.gold.opacity(0.09)))
            }
            if let s = dhikr.s {
                Text(s).rawhText(12).foregroundStyle(app.skin.sub)
            }
            Divider().overlay(app.skin.line)
            HStack(spacing: 14) {
                if !dhikr.audioURLs.isEmpty {
                    let playing = audio.playingId == dhikr.id
                    action(playing ? "stop.fill" : "play.fill", playing) { audio.toggle(id: dhikr.id, urls: dhikr.audioURLs) }
                }
                action("doc.on.doc", copied) {
                    UIPasteboard.general.string = dhikr.t
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copied = false }
                }
                action("square.and.arrow.up", false) { onShare() }
                Button {
                    favTick += 1; app.toggleFav(dhikr)
                } label: {
                    Image(systemName: app.isFav(dhikr) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(app.isFav(dhikr) ? app.skin.gold : app.skin.sub)
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce.up, value: favTick)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: favTick)
                Spacer()
                // عدّاد
                Button {
                    tick += 1; onTap()
                } label: {
                    ZStack {
                        ProgressRing(progress: Double(cnt) / Double(max(1, dhikr.n)), color: done ? app.skin.green : app.skin.gold, track: app.skin.gold.opacity(0.14), width: 4)
                        if done {
                            Image(systemName: "checkmark").font(.system(size: 18, weight: .bold)).foregroundStyle(app.skin.green)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text(AR.n(rem)).rawhText(18, .bold).foregroundStyle(app.skin.text)
                                .contentTransition(.numericText(countsDown: true))
                        }
                    }
                    .frame(width: 54, height: 54)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .surface(24, skin: app.skin, stroke: done ? app.skin.green.opacity(0.55) : nil)
        .contentShape(Rectangle())
        .onTapGesture { if !done { tick += 1; onTap() } }
        .scaleEffect(tick % 2 == 0 ? 1 : 0.995)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: tick)
        .sensoryFeedback(.impact(weight: .light), trigger: tick)
    }

    private func action(_ symbol: String, _ on: Bool, _ run: @escaping () -> Void) -> some View {
        ActionIcon(symbol: symbol, on: on, run: run)
    }
}

struct ActionIcon: View {
    @EnvironmentObject var app: AppState
    var symbol: String
    var on: Bool
    var run: () -> Void
    @State private var t = 0
    var body: some View {
        Button { t += 1; run() } label: {
            Image(systemName: on && symbol == "doc.on.doc" ? "checkmark" : symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(on ? app.skin.gold : app.skin.sub)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: t)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: t)
    }
}

struct FocusPage: View {
    @EnvironmentObject var app: AppState
    let dhikr: Dhikr
    let cat: AdhkarCategory
    var onTap: () -> Void
    @State private var tick = 0
    var body: some View {
        let rem = app.remaining(dhikr)
        VStack(spacing: 22) {
            Spacer(minLength: 10)
            Ornament(width: 160)
            if let h = dhikr.h { Text(h).rawhText(14, .semibold).foregroundStyle(app.skin.gold) }
            ScrollView {
                Text(dhikr.t)
                    .rawhText(27 * app.s.textScale, .regular)
                    .lineSpacing(14 * app.s.textScale)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(app.skin.text)
                    .padding(.horizontal, 26)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 420)
            ZStack {
                ProgressRing(progress: Double(app.count(of: dhikr)) / Double(max(1, dhikr.n)), color: rem == 0 ? app.skin.green : app.skin.gold, track: app.skin.gold.opacity(0.14), width: 6)
                if rem == 0 {
                    Image(systemName: "checkmark").font(.system(size: 30, weight: .bold)).foregroundStyle(app.skin.green)
                } else {
                    Text(AR.n(rem)).rawhText(34, .bold).foregroundStyle(app.skin.text)
                        .contentTransition(.numericText(countsDown: true))
                }
            }
            .frame(width: 104, height: 104)
            Text(rem == 0 ? "اسحب للذكر التالي" : "اضغط في أي مكان للعدّ").rawhText(13).foregroundStyle(app.skin.sub)
            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { if rem > 0 { tick += 1; withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { onTap() } } }
        .sensoryFeedback(.impact(weight: .medium), trigger: tick)
    }
}

// MARK: - مشاركة الذكر كبطاقة

struct ShareCardView: View {
    let dhikr: Dhikr
    let cat: AdhkarCategory
    let skin: Skin
    var body: some View {
        ZStack {
            LinearGradient(colors: [skin.bg, skin.bg2], startPoint: .top, endPoint: .bottom)
            PatternBackground(color: skin.gold, opacity: 0.08, cell: 70)
            RoundedRectangle(cornerRadius: 0).strokeBorder(skin.gold.opacity(0.5), lineWidth: 2).padding(22)
            VStack(spacing: 26) {
                ArchShape(shoulder: 0.38).stroke(skin.gold, lineWidth: 3).frame(width: 64, height: 82)
                    .overlay(StarBurst().fill(skin.goldLight).frame(width: 14, height: 14).offset(y: -50))
                if let h = dhikr.h { Text(h).font(.system(size: 26, weight: .semibold)).foregroundStyle(skin.gold) }
                Text(dhikr.t)
                    .font(.system(size: dhikr.t.count > 300 ? 30 : 40, weight: .regular))
                    .lineSpacing(18)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(skin.text)
                    .padding(.horizontal, 70)
                if let s = dhikr.s { Text(s).font(.system(size: 22)).foregroundStyle(skin.text.opacity(0.6)) }
                Spacer().frame(height: 10)
                Text("رَوْح · \(cat.t)").font(.system(size: 22, weight: .semibold)).foregroundStyle(skin.gold)
            }
            .padding(.vertical, 90)
        }
        .frame(width: 1080, height: 1350)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct ShareSheet: View {
    @EnvironmentObject var app: AppState
    let dhikr: Dhikr
    let cat: AdhkarCategory
    @State private var image: UIImage? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                VStack(spacing: 20) {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
                            .padding(.horizontal, 30)
                        ShareLink(item: Image(uiImage: image), preview: SharePreview(cat.t, image: Image(uiImage: image))) {
                            Label("شارك البطاقة", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(GoldButtonStyle(skin: app.skin))
                    } else {
                        ProgressView().tint(app.skin.gold)
                    }
                    ShareLink(item: dhikr.t + (dhikr.s.map { "\n\n" + $0 } ?? "")) {
                        Label("شارك النص", systemImage: "text.quote")
                    }
                    .buttonStyle(GhostButtonStyle(skin: app.skin))
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("مشاركة الذكر")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { Task { @MainActor in render() } }
    }

    @MainActor private func render() {
        let r = ImageRenderer(content: ShareCardView(dhikr: dhikr, cat: cat, skin: app.skin))
        r.scale = 1
        image = r.uiImage
    }
}


// MARK: - القرآن الكريم (نص عثماني من alquran.cloud وتلاوة العفاسي)

struct SurahInfo: Codable, Identifiable, Hashable {
    let number: Int
    let name: String
    let englishName: String
    let numberOfAyahs: Int
    let revelationType: String
    var id: Int { number }
    var plainName: String { name.replacingOccurrences(of: "سُورَةُ ", with: "") }
}

struct Ayah: Codable, Identifiable, Hashable {
    let number: Int
    let text: String
    let numberInSurah: Int
    var id: Int { number }
}

private struct SurahListResponse: Codable { let data: [SurahInfo] }
private struct SurahDetail: Codable { let number: Int; let ayahs: [Ayah] }
private struct SurahResponse: Codable { let data: SurahDetail }
private struct AyahResponse: Codable { let data: Ayah }

final class QuranStore: ObservableObject {
    static let shared = QuranStore()
    @Published var surahs: [SurahInfo] = []
    @Published var loadingList = false
    @Published var failed = false
    private let base = "https://api.alquran.cloud/v1"

    private func cacheURL(_ name: String) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("quran", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(name)
    }

    private func fetch(_ path: String, cache: String) async throws -> Data {
        let file = cacheURL(cache)
        if let d = try? Data(contentsOf: file) { return d }
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        let (d, _) = try await URLSession.shared.data(from: url)
        try? d.write(to: file)
        return d
    }

    @MainActor func loadList() async {
        if !surahs.isEmpty || loadingList { return }
        loadingList = true; failed = false
        do {
            let d = try await fetch("/surah", cache: "surahs.json")
            surahs = try JSONDecoder().decode(SurahListResponse.self, from: d).data
        } catch {
            failed = true
            try? FileManager.default.removeItem(at: cacheURL("surahs.json"))
        }
        loadingList = false
    }

    func surah(_ n: Int) async throws -> [Ayah] {
        do {
            let d = try await fetch("/surah/\(n)/quran-uthmani", cache: "s\(n).json")
            return try JSONDecoder().decode(SurahResponse.self, from: d).data.ayahs
        } catch {
            try? FileManager.default.removeItem(at: cacheURL("s\(n).json"))
            throw error
        }
    }

    /// مرجع مثل "2:201" أو "20:25-28"
    func verses(_ ref: String) async throws -> [Ayah] {
        let parts = ref.split(separator: ":")
        guard parts.count == 2, let s = Int(parts[0]) else { return [] }
        let range = parts[1].split(separator: "-").compactMap { Int($0) }
        guard let a = range.first else { return [] }
        let b = range.count > 1 ? range[1] : a
        var out: [Ayah] = []
        for i in a...b {
            let d = try await fetch("/ayah/\(s):\(i)/quran-uthmani", cache: "a\(s)_\(i).json")
            out.append(try JSONDecoder().decode(AyahResponse.self, from: d).data)
        }
        return out
    }

    static func audioURL(_ globalNumber: Int) -> URL? {
        URL(string: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/\(globalNumber).mp3")
    }
}

struct QuranView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var store = QuranStore.shared
    @State private var query = ""
    @State private var filter = 0 // 0 الكل، 1 مكية، 2 مدنية

    var filtered: [SurahInfo] {
        store.surahs.filter { s in
            (filter == 0 || (filter == 1 ? s.revelationType == "Meccan" : s.revelationType == "Medinan")) &&
            (query.isEmpty || AR.normalize(s.plainName).contains(AR.normalize(query)) || AR.n(s.number) == query || "\(s.number)" == query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Ornament(width: 200)
                            Text("القرآن الكريم").rawhText(32, .bold).foregroundStyle(app.skin.text)
                            Text("برواية حفص عن عاصم · بالرسم العثماني · بصوت مشاري العفاسي")
                                .rawhText(12).foregroundStyle(app.skin.sub).multilineTextAlignment(.center)
                        }
                        .padding(.top, 14)

                        if app.s.lastSurah > 0, let last = store.surahs.first(where: { $0.number == app.s.lastSurah }) {
                            NavigationLink(value: last) {
                                Card(highlight: true) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "bookmark.fill").font(.system(size: 22)).foregroundStyle(app.skin.gold)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("تابع القراءة").rawhText(12).foregroundStyle(app.skin.sub)
                                            Text("\(last.plainName) · الآية \(AR.n(max(1, app.s.lastAyah)))").rawhText(17, .bold).foregroundStyle(app.skin.text)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.left").foregroundStyle(app.skin.gold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 10) {
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundStyle(app.skin.sub)
                                TextField("ابحث عن سورة", text: $query).foregroundStyle(app.skin.text)
                            }
                            .padding(12)
                            .surface(14, skin: app.skin)
                        }
                        Picker("", selection: $filter) {
                            Text("الكل").tag(0); Text("مكية").tag(1); Text("مدنية").tag(2)
                        }
                        .pickerStyle(.segmented)

                        if store.loadingList && store.surahs.isEmpty {
                            ProgressView().tint(app.skin.gold).padding(40)
                        } else if store.failed && store.surahs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "wifi.exclamationmark").font(.system(size: 34)).foregroundStyle(app.skin.gold)
                                Text("تحتاج اتصالاً بالإنترنت لتحميل المصحف أول مرة").rawhText(14).foregroundStyle(app.skin.sub).multilineTextAlignment(.center)
                                Button("إعادة المحاولة") { Task { await store.loadList() } }.buttonStyle(GoldButtonStyle(skin: app.skin))
                            }
                            .padding(30)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { s in
                                    NavigationLink(value: s) { SurahRow(s: s) }.buttonStyle(.plain).scrollReveal()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SurahInfo.self) { s in SurahView(info: s).environmentObject(app) }
            .task { await store.loadList() }
        }
    }
}

struct AyahNumber: View {
    @EnvironmentObject var app: AppState
    var n: Int
    var size: CGFloat = 34
    var body: some View {
        ZStack {
            EightStar().stroke(app.skin.gold, lineWidth: 1.1)
            Text(AR.n(n)).rawhText(size * 0.34, .bold).foregroundStyle(app.skin.text).minimumScaleFactor(0.6)
        }
        .frame(width: size, height: size)
    }
}

struct SurahRow: View {
    @EnvironmentObject var app: AppState
    var s: SurahInfo
    var body: some View {
        HStack(spacing: 14) {
            AyahNumber(n: s.number, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(s.plainName).rawhText(18, .bold).foregroundStyle(app.skin.text)
                Text("\(s.revelationType == "Meccan" ? "مكية" : "مدنية") · \(AR.n(s.numberOfAyahs)) آية").rawhText(12).foregroundStyle(app.skin.sub)
            }
            Spacer()
            Text(s.englishName).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(app.skin.sub)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(14)
        .surface(18, skin: app.skin)
    }
}

struct SurahView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject private var audio = AudioPlayer.shared
    let info: SurahInfo
    @State private var ayahs: [Ayah] = []
    @State private var failed = false
    @State private var selected: Ayah? = nil

    static let bismillah = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
    private var playId: String { "surah:\(info.number)" }

    private func display(_ a: Ayah) -> String {
        if info.number != 1 && a.numberInSurah == 1 && a.text.hasPrefix(Self.bismillah) {
            return String(a.text.dropFirst(Self.bismillah.count)).trimmingCharacters(in: .whitespaces)
        }
        return a.text
    }

    private func play(from i: Int) {
        let urls = ayahs.compactMap { QuranStore.audioURL($0.number) }
        audio.play(id: playId, urls: urls, from: i)
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // ترويسة السورة
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(app.skin.gold.opacity(0.6), lineWidth: 1.2).padding(6)
                            HStack {
                                EightStar().stroke(app.skin.gold, lineWidth: 1).frame(width: 30, height: 30)
                                Spacer()
                                VStack(spacing: 4) {
                                    Text(info.name).rawhText(26, .bold).foregroundStyle(app.skin.text)
                                    Text("\(info.revelationType == "Meccan" ? "مكية" : "مدنية") · \(AR.n(info.numberOfAyahs)) آية").rawhText(12).foregroundStyle(app.skin.sub)
                                }
                                Spacer()
                                EightStar().stroke(app.skin.gold, lineWidth: 1).frame(width: 30, height: 30)
                            }
                            .padding(.horizontal, 22)
                        }
                        .frame(height: 96)
                        .surface(20, skin: app.skin, stroke: app.skin.gold.opacity(0.35))

                        if info.number != 1 && info.number != 9 {
                            Text(Self.bismillah).rawhText(24 * app.s.textScale, .medium).foregroundStyle(app.skin.gold)
                        }

                        if ayahs.isEmpty {
                            if failed {
                                VStack(spacing: 10) {
                                    Text("تعذّر تحميل السورة. تأكد من اتصالك.").rawhText(14).foregroundStyle(app.skin.sub)
                                    Button("إعادة المحاولة") { Task { await load() } }.buttonStyle(GoldButtonStyle(skin: app.skin))
                                }.padding(30)
                            } else {
                                ProgressView().tint(app.skin.gold).padding(40)
                            }
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(Array(ayahs.enumerated()), id: \.element.id) { i, a in
                                    let current = audio.playingId == playId && audio.index == i
                                    let marked = app.s.lastSurah == info.number && app.s.lastAyah == a.numberInSurah
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(display(a))
                                            .rawhText(25 * app.s.textScale, .regular)
                                            .lineSpacing(16 * app.s.textScale)
                                            .foregroundStyle(app.skin.text)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                        HStack {
                                            AyahNumber(n: a.numberInSurah, size: 32)
                                            if marked { Image(systemName: "bookmark.fill").foregroundStyle(app.skin.gold).font(.system(size: 13)) }
                                            Spacer()
                                            if current {
                                                Image(systemName: "waveform").foregroundStyle(app.skin.gold)
                                                    .symbolEffect(.variableColor.iterative, isActive: true)
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .surface(18, skin: app.skin, tint: current ? app.skin.gold.opacity(0.3) : nil, stroke: current ? app.skin.gold.opacity(0.7) : nil)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selected = a }
                                    .id(a.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                .onChange(of: audio.index) { _, i in
                    if audio.playingId == playId, i < ayahs.count {
                        withAnimation(.easeInOut(duration: 0.5)) { proxy.scrollTo(ayahs[i].id, anchor: .center) }
                    }
                }
                .onChange(of: ayahs.count) { _, _ in
                    if app.s.lastSurah == info.number, app.s.lastAyah > 1, let a = ayahs.first(where: { $0.numberInSurah == app.s.lastAyah }) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { proxy.scrollTo(a.id, anchor: .top) }
                    }
                }
            }
        }
        .navigationTitle(info.plainName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if audio.playingId == playId { audio.stop() } else { play(from: 0) }
                } label: {
                    Image(systemName: audio.playingId == playId ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(app.skin.gold)
                        .contentTransition(.symbolEffect(.replace))
                }
                .disabled(ayahs.isEmpty)
            }
        }
        .confirmationDialog("الآية \(AR.n(selected?.numberInSurah ?? 0))", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } }), titleVisibility: .visible) {
            if let a = selected, let i = ayahs.firstIndex(of: a) {
                Button("استمع من هذه الآية") { play(from: i) }
                Button("ضع علامة القراءة هنا") { app.s.lastSurah = info.number; app.s.lastAyah = a.numberInSurah }
                Button("انسخ الآية") { UIPasteboard.general.string = "\(display(a)) ﴿\(AR.n(a.numberInSurah))﴾\n\(info.name)" }
                Button("إلغاء", role: .cancel) { selected = nil }
            }
        }
        .task { await load() }
        .onDisappear { if audio.playingId == playId { /* تستمر التلاوة في الخلفية حتى توقفها */ } }
    }

    @MainActor private func load() async {
        failed = false
        do { ayahs = try await QuranStore.shared.surah(info.number) } catch { failed = true }
    }
}


// MARK: - السبحة

struct SebhaView: View {
    @EnvironmentObject var app: AppState
    @State private var tap = 0
    @State private var round = 0
    @State private var resetTick = 0
    @State private var pressed = false

    var body: some View {
        let phrases = DB.data.phrases
        let target = app.s.sebhaTarget
        let count = app.s.sebhaCount
        let inRound = count == 0 ? 0 : ((count - 1) % target) + 1
        let p = Double(inRound) / Double(target)
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 6) {
                            Ornament(width: 180)
                            Text("السبحة").rawhText(30, .bold).foregroundStyle(app.skin.text)
                        }
                        .padding(.top, 14)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(phrases.enumerated()), id: \.offset) { i, ph in
                                    Button {
                                        app.s.sebhaPhrase = i
                                    } label: {
                                        Text(ph).rawhText(14, .medium)
                                            .foregroundStyle(i == app.s.sebhaPhrase ? app.skin.onGold : app.skin.text)
                                            .padding(.horizontal, 14).padding(.vertical, 9)
                                            .glassCapsule(skin: app.skin, tint: i == app.s.sebhaPhrase ? app.skin.gold : nil)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 18)
                        }

                        Text(phrases[min(app.s.sebhaPhrase, phrases.count - 1)])
                            .rawhText(26, .semibold).foregroundStyle(app.skin.gold)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                            .contentTransition(.opacity)
                            .animation(.easeInOut, value: app.s.sebhaPhrase)

                        // حبات السبحة حول الزر
                        ZStack {
                            BeadRing(total: 33, lit: Int((p * 33).rounded()), color: app.skin.gold, dim: app.skin.gold.opacity(0.16))
                                .frame(width: 290, height: 290)
                                .rotationEffect(.degrees(Double(count) * 360.0 / 33.0))
                                .animation(.spring(response: 0.42, dampingFraction: 0.7), value: count)
                            ProgressRing(progress: p, color: app.skin.gold, track: .clear, width: 3)
                                .frame(width: 240, height: 240)
                            Button {
                                tap += 1
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { app.sebhaTap() }
                                if app.s.sebhaCount % target == 0 { round += 1 }
                            } label: {
                                ZStack {
                                    EightStar().stroke(app.skin.gold.opacity(0.12), lineWidth: 1).padding(30)
                                    VStack(spacing: 4) {
                                        Text(AR.n(inRound)).rawhText(58, .bold).foregroundStyle(app.skin.text)
                                            .contentTransition(.numericText())
                                        Text("من \(AR.n(target))").rawhText(13).foregroundStyle(app.skin.sub)
                                    }
                                }
                                .frame(width: 210, height: 210)
                                .beadSurface(app.skin)
                            }
                            .buttonStyle(PressScale())
                        }
                        .sensoryFeedback(.impact(weight: .light), trigger: tap)
                        .sensoryFeedback(.success, trigger: round)

                        HStack(spacing: 22) {
                            stat("الدورات", app.s.sebhaCount / max(1, target))
                            stat("المجموع", app.s.sebhaCount)
                            stat("اليوم", app.todayCount)
                        }

                        HStack(spacing: 10) {
                            Picker("الهدف", selection: Binding(get: { app.s.sebhaTarget }, set: { app.s.sebhaTarget = $0 })) {
                                ForEach([33, 100, 1000], id: \.self) { Text(AR.n($0)).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 220)
                            Button {
                                resetTick += 1
                                withAnimation { app.s.sebhaCount = 0; app.s.sebhaRounds = 0 }
                            } label: {
                                Label("تصفير", systemImage: "arrow.counterclockwise")
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(GhostButtonStyle(skin: app.skin))
                            .spin(on: resetTick)
                            .sensoryFeedback(.warning, trigger: resetTick)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func stat(_ t: String, _ v: Int) -> some View {
        VStack(spacing: 3) {
            Text(AR.n(v)).rawhText(20, .bold).foregroundStyle(app.skin.text).contentTransition(.numericText())
            Text(t).rawhText(12).foregroundStyle(app.skin.sub)
        }
        .frame(minWidth: 70)
    }
}

struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

struct BeadRing: View {
    var total: Int
    var lit: Int
    var color: Color
    var dim: Color
    var body: some View {
        GeometryReader { g in
            let r = min(g.size.width, g.size.height) / 2 - 9
            let c = CGPoint(x: g.size.width / 2, y: g.size.height / 2)
            ZStack {
                ForEach(0..<total, id: \.self) { i in
                    let a = Double(i) / Double(total) * 2 * Double.pi - Double.pi / 2
                    Circle()
                        .fill(RadialGradient(colors: i < lit ? [Color.white.opacity(0.85), color, color.opacity(0.7)] : [dim.opacity(1.6), dim],
                                             center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 9))
                        .shadow(color: i < lit ? color.opacity(0.45) : .clear, radius: 3)
                        .frame(width: i == 0 ? 16 : 12, height: i == 0 ? 16 : 12)
                        .position(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lit)
                }
            }
        }
    }
}

// MARK: - إنجازي

struct StatsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(spacing: 6) {
                            Ornament(width: 180)
                            Text("إنجازي").rawhText(30, .bold).foregroundStyle(app.skin.text)
                            Text("يُحفظ في جهازك فقط").rawhText(12).foregroundStyle(app.skin.sub)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            tile("flame.fill", "أيام متتالية من الوِرد", app.streak, breathe: app.streak > 0)
                            tile("hand.tap.fill", "ذكرًا وتسبيحة اليوم", app.todayCount)
                            tile("sparkles", "مجموع ما ذكرت", app.totalCount)
                            tile("checkmark.seal.fill", "أقسام أتممتها اليوم", (app.s.done[AR.dayKey()] ?? []).count)
                        }

                        SectionTitle(title: "آخر ٢٨ يومًا")
                        Card { Heatmap() }

                        SectionTitle(title: "أقسام اليوم")
                        VStack(spacing: 10) {
                            ForEach(DB.cats) { c in
                                HStack(spacing: 12) {
                                    CategoryIcon(ic: c.ic, size: 36)
                                    Text(c.t).rawhText(15, .semibold).foregroundStyle(app.skin.text)
                                    Spacer()
                                    ZStack {
                                        ProgressRing(progress: app.progress(c), color: app.skin.gold, track: app.skin.gold.opacity(0.14), width: 3.5)
                                        Text("\(AR.n(Int(app.progress(c) * 100)))٪").rawhText(10, .bold).foregroundStyle(app.skin.text)
                                    }
                                    .frame(width: 42, height: 42)
                                }
                                .padding(12)
                                .surface(16, skin: app.skin)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func tile(_ symbol: String, _ label: String, _ v: Int, breathe: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(app.skin.gold)
                .breathing(breathe)
            Text(AR.n(v)).rawhText(30, .bold).foregroundStyle(app.skin.text).contentTransition(.numericText())
            Text(label).rawhText(12.5).foregroundStyle(app.skin.sub)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(20, skin: app.skin)
    }
}

struct Heatmap: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        let g = AR.gregorian
        let today = g.startOfDay(for: Date())
        let days: [Date] = (0..<28).reversed().compactMap { g.date(byAdding: .day, value: -$0, to: today) }
        let maxV = max(1, days.map { app.s.history[AR.dayKey($0)] ?? 0 }.max() ?? 1)
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { d in
                    let v = app.s.history[AR.dayKey(d)] ?? 0
                    let done = !(app.s.done[AR.dayKey(d)] ?? []).isEmpty
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(v == 0 ? app.skin.gold.opacity(0.08) : app.skin.gold.opacity(0.25 + 0.75 * Double(v) / Double(maxV)))
                        .overlay(done ? StarBurst().fill(app.skin.onGold.opacity(0.8)).padding(9) : nil)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            HStack(spacing: 6) {
                Text("أقل").rawhText(11).foregroundStyle(app.skin.sub)
                ForEach([0.08, 0.35, 0.6, 1.0], id: \.self) { o in
                    RoundedRectangle(cornerRadius: 3).fill(app.skin.gold.opacity(o)).frame(width: 12, height: 12)
                }
                Text("أكثر").rawhText(11).foregroundStyle(app.skin.sub)
                Spacer()
                StarBurst().fill(app.skin.gold).frame(width: 10, height: 10)
                Text("أتممت وِردًا").rawhText(11).foregroundStyle(app.skin.sub)
            }
        }
    }
}


// MARK: - المزيد

enum MoreRoute: Hashable { case names, duas, occasions, reminders, qibla, favorites }

struct MoreView: View {
    @EnvironmentObject var app: AppState
    @State private var showSettings = false
    @State private var showIntro = false
    @State private var path: [MoreRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Ornament(width: 180)
                            Text("المزيد").rawhText(30, .bold).foregroundStyle(app.skin.text)
                            Text("كل ما يعينك على يومك مع الله، في مكان واحد").rawhText(13).foregroundStyle(app.skin.sub)
                        }
                        .padding(.top, 14)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            hub("أسماء الله الحسنى", "تسعة وتسعون اسمًا", custom: AnyView(EightStar().stroke(app.skin.gold, lineWidth: 1.6).frame(width: 24, height: 24))) { path.append(.names) }
                            hub("أدعية من القرآن", "\(AR.n(DB.data.duas.count)) دعاءً بنص المصحف", symbol: "hands.and.sparkles.fill") { path.append(.duas) }
                            hub("المناسبات الإسلامية", "رمضان والأعياد والأيام الفاضلة", symbol: "moon.circle.fill") { path.append(.occasions) }
                            hub("التذكيرات", "إشعارات للأذكار والصلاة والصيام", symbol: "bell.fill", wiggle: true) { path.append(.reminders) }
                            hub("اتجاه القبلة", "بوصلة تتوجه حين تتجه", symbol: "location.north.circle.fill") { path.append(.qibla) }
                            hub("المحفوظة", "\(AR.n(app.s.favorites.count)) ذكرًا محفوظًا", symbol: "bookmark.fill") { path.append(.favorites) }
                            hub("المظهر والإعدادات", "الألوان والخط والمدينة", symbol: "paintpalette.fill") { showSettings = true }
                            hub("المقدمة", "شاهد التعريف بالتطبيق", symbol: "play.fill") { showIntro = true }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack { Image(systemName: "apps.iphone").foregroundStyle(app.skin.gold); Text("الودجت و Siri").rawhText(15, .bold).foregroundStyle(app.skin.text) }
                                Text("أضف ودجت «الصلاة القادمة» أو «ذكر الساعة» من الشاشة الرئيسية أو شاشة القفل: اضغط مطوّلًا ← تعديل ← إضافة أداة ← رَوْح.\nوقل لـ Siri: «أذكار الصباح في رَوْح» أو «كم باقي على الصلاة في رَوْح».")
                                    .rawhText(13).foregroundStyle(app.skin.sub).lineSpacing(5)
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack { Image(systemName: "book.closed.fill").foregroundStyle(app.skin.gold); Text("المصادر").rawhText(15, .bold).foregroundStyle(app.skin.text) }
                                Text("الأذكار مرتّبة على «حصن المسلم» مع تخريج كل ذكر. نص المصحف بالرسم العثماني والتلاوة بصوت الشيخ مشاري العفاسي. المواقيت بطريقة أم القرى.")
                                    .rawhText(13).foregroundStyle(app.skin.sub).lineSpacing(5)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MoreRoute.self) { r in
                Group {
                    switch r {
                    case .names: NamesView()
                    case .duas: DuasView()
                    case .occasions: OccasionsView()
                    case .reminders: RemindersView()
                    case .qibla: QiblaView(city: app.city)
                    case .favorites: FavoritesView()
                    }
                }
                .environmentObject(app)
            }
            .sheet(isPresented: $showSettings) { SettingsView().environmentObject(app) }
            .fullScreenCover(isPresented: $showIntro) { IntroView().environmentObject(app) }
        }
    }

    private func hub(_ t: String, _ d: String, symbol: String = "", custom: AnyView? = nil, wiggle: Bool = false, _ go: @escaping () -> Void) -> some View {
        HubTile(title: t, detail: d, symbol: symbol, custom: custom, wiggleIt: wiggle, go: go)
    }
}

struct HubTile: View {
    @EnvironmentObject var app: AppState
    var title: String
    var detail: String
    var symbol: String
    var custom: AnyView?
    var wiggleIt: Bool
    var go: () -> Void
    @State private var t = 0
    var body: some View {
        Button { t += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { go() } } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous).fill(app.skin.gold.opacity(0.14))
                    if let custom { custom }
                    else if wiggleIt {
                        Image(systemName: symbol).font(.system(size: 20, weight: .medium)).foregroundStyle(app.skin.gold).wiggle(on: t)
                    } else {
                        Image(systemName: symbol).font(.system(size: 20, weight: .medium)).foregroundStyle(app.skin.gold).symbolEffect(.bounce, value: t)
                    }
                }
                .frame(width: 44, height: 44)
                Text(title).rawhText(15.5, .bold).foregroundStyle(app.skin.text).lineLimit(1).minimumScaleFactor(0.8)
                Text(detail).rawhText(12).foregroundStyle(app.skin.sub).lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .surface(20, skin: app.skin)
        }
        .buttonStyle(PressScale())
        .sensoryFeedback(.selection, trigger: t)
    }
}

struct SubScreen<C: View>: View {
    @EnvironmentObject var app: AppState
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> C
    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 6) {
                        Ornament(width: 160)
                        Text(title).rawhText(26, .bold).foregroundStyle(app.skin.text)
                        if let subtitle { Text(subtitle).rawhText(13).foregroundStyle(app.skin.sub).multilineTextAlignment(.center) }
                    }
                    .padding(.top, 6)
                    content()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// أسماء الله الحسنى
struct NamesView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        SubScreen(title: "أسماء الله الحسنى", subtitle: "«إن لله تسعة وتسعين اسمًا، من أحصاها دخل الجنة» متفق عليه") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Array(DB.data.names.enumerated()), id: \.offset) { i, n in
                    VStack(spacing: 8) {
                        ZStack {
                            EightStar().stroke(app.skin.gold.opacity(0.45), lineWidth: 1)
                            Text(AR.n(i + 1)).rawhText(10, .bold).foregroundStyle(app.skin.gold)
                        }
                        .frame(width: 30, height: 30)
                        Text(n).rawhText(17, .bold).foregroundStyle(app.skin.text).minimumScaleFactor(0.6).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .surface(16, skin: app.skin)
                }
            }
        }
    }
}

// أدعية من القرآن
struct DuasView: View {
    @EnvironmentObject var app: AppState
    @State private var texts: [String: String] = [:]
    @State private var failed = false
    var body: some View {
        SubScreen(title: "أدعية من القرآن", subtitle: "بنص المصحف الشريف") {
            if failed && texts.isEmpty {
                Text("تحتاج اتصالاً بالإنترنت لتحميل الأدعية أول مرة").rawhText(14).foregroundStyle(app.skin.sub).padding(30)
            }
            ForEach(DB.data.duas) { d in
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(d.t).rawhText(14, .bold).foregroundStyle(app.skin.gold)
                            Spacer()
                            Text(refLabel(d.ref)).rawhText(11).foregroundStyle(app.skin.sub)
                        }
                        if let t = texts[d.ref] {
                            Text(t).rawhText(21 * app.s.textScale).lineSpacing(10).foregroundStyle(app.skin.text)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack {
                                Spacer()
                                ShareLink(item: t) { Image(systemName: "square.and.arrow.up").foregroundStyle(app.skin.sub) }
                            }
                        } else {
                            ProgressView().tint(app.skin.gold)
                        }
                    }
                }
            }
        }
        .task {
            for d in DB.data.duas where texts[d.ref] == nil {
                do {
                    let a = try await QuranStore.shared.verses(d.ref)
                    texts[d.ref] = a.map { "\($0.text) ﴿\(AR.n($0.numberInSurah))﴾" }.joined(separator: " ")
                } catch { failed = true }
            }
        }
    }
    private func refLabel(_ r: String) -> String {
        let p = r.split(separator: ":")
        guard p.count == 2, let s = Int(p[0]) else { return r }
        return "سورة \(AR.n(s)) · الآية \(p[1].split(separator: "-").compactMap { Int($0) }.map { AR.n($0) }.joined(separator: "–"))"
    }
}

// المناسبات
struct OccasionsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        let list = Occasions.upcoming()
        SubScreen(title: "المناسبات الإسلامية", subtitle: "بتقويم أم القرى") {
            ForEach(list) { o in
                Card(highlight: o.days == 0) {
                    HStack(spacing: 14) {
                        CategoryIcon(ic: o.occ.ic, size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(o.occ.t).rawhText(16, .bold).foregroundStyle(app.skin.text)
                            Text(AR.hijriString(o.date)).rawhText(12.5).foregroundStyle(app.skin.gold)
                            Text(AR.dayF.string(from: o.date)).rawhText(12).foregroundStyle(app.skin.sub)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            if o.days == 0 {
                                Text("اليوم").rawhText(16, .bold).foregroundStyle(app.skin.gold)
                            } else {
                                Text(AR.n(o.days)).rawhText(22, .bold).foregroundStyle(app.skin.text)
                                Text(o.days == 1 ? "يوم" : (o.days <= 10 ? "أيام" : "يومًا")).rawhText(11).foregroundStyle(app.skin.sub)
                            }
                        }
                    }
                }
            }
        }
    }
}

// التذكيرات
enum TestState { case idle, sending, sent, denied }

struct RemindersView: View {
    @EnvironmentObject var app: AppState
    @State private var bell = 0
    @State private var testKind = "morning"
    @State private var testTick = 0
    @State private var testState: TestState = .idle
    var body: some View {
        SubScreen(title: "التذكيرات", subtitle: "تصلك إشعارات من الجوال حتى لو كان التطبيق مقفلاً") {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.palette)
                .foregroundStyle(app.skin.gold, app.skin.text)
                .wiggle(on: bell)
                .padding(.vertical, 6)
            // تجربة التنبيه
            VStack(alignment: .leading, spacing: 12) {
                Label("جرّب التنبيه", systemImage: "bell.and.waves.left.and.right.fill")
                    .rawhText(16, .semibold).foregroundStyle(app.skin.text)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Reminders.testKinds, id: \.key) { k in
                            Button { testKind = k.key } label: {
                                Text(k.title).rawhText(13, .semibold)
                                    .foregroundStyle(testKind == k.key ? app.skin.onGold : app.skin.text)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .glassCapsule(skin: app.skin, tint: testKind == k.key ? app.skin.gold : nil, fallback: testKind == k.key ? app.skin.gold : app.skin.card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Button {
                    testTick += 1
                    testState = .sending
                    Reminders.sendTest(testKind, app.s) { ok in
                        testState = ok ? .sent : .denied
                        if ok { DispatchQueue.main.asyncAfter(deadline: .now() + 6) { if testState == .sent { testState = .idle } } }
                    }
                } label: {
                    Label(testState == .sent ? "بيوصلك بعد ٥ ثوانٍ…" : "أرسل تنبيه تجربة", systemImage: testState == .sent ? "timer" : "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(GoldButtonStyle(skin: app.skin))
                .symbolEffect(.bounce, value: testTick)
                .disabled(testState == .sending)
                if testState == .denied {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("الإشعارات مقفلة لـ رَوْح. فعّلها من الإعدادات عشان توصلك الأذكار.").rawhText(13).foregroundStyle(app.skin.text)
                        Button("افتح إعدادات الإشعارات") {
                            if let u = URL(string: UIApplication.openNotificationSettingsURLString) { UIApplication.shared.open(u) }
                        }
                        .buttonStyle(GhostButtonStyle(skin: app.skin))
                    }
                } else {
                    Text("اقفل الشاشة بعد ما تضغط، وبتشوف التنبيه وتسمع صوته مثل ما يوصلك بالضبط.").rawhText(12).foregroundStyle(app.skin.sub)
                }
            }
            .padding(16)
            .surface(20, skin: app.skin)
            .sensoryFeedback(.success, trigger: testTick)

            // صوت التنبيه
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(get: { app.s.voiceAlerts }, set: { v in
                    app.s.voiceAlerts = v
                    bell += 1
                    VoiceAlerts.prepare { Reminders.schedule(app.s) }
                })) {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("صوت ينطق التنبيه", systemImage: "speaker.wave.2.bubble.fill").rawhText(16, .semibold).foregroundStyle(app.skin.text)
                        Text("مثل: «أذكار الصباح، أثابكم الله» بدل النغمة").rawhText(12).foregroundStyle(app.skin.sub)
                    }
                }
                .tint(app.skin.gold)
                if app.s.voiceAlerts { VoicePreviewRow() }
            }
            .padding(16)
            .surface(20, skin: app.skin)

            VStack(spacing: 0) {
                ForEach(Reminders.items) { r in
                    Toggle(isOn: Binding(get: { app.s.reminders[r.id] ?? false }, set: { v in
                        app.s.reminders[r.id] = v
                        bell += 1
                        Reminders.requestAndSchedule(app.s)
                    })) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(r.t).rawhText(16, .semibold).foregroundStyle(app.skin.text)
                            Text(r.d).rawhText(12).foregroundStyle(app.skin.sub)
                        }
                    }
                    .tint(app.skin.gold)
                    .padding(.vertical, 12)
                    if r.id == "daily" && app.s.reminders["daily"] == true {
                        Picker("كل", selection: Binding(get: { app.s.reminderEvery }, set: { app.s.reminderEvery = $0; Reminders.schedule(app.s) })) {
                            Text("كل ساعتين").tag(2); Text("كل ٣ ساعات").tag(3); Text("كل ٤ ساعات").tag(4)
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 12)
                    }
                    if r.id != Reminders.items.last?.id { Divider().overlay(app.skin.line) }
                }
            }
            .padding(.horizontal, 16)
            .surface(20, skin: app.skin)
            // معاينة شكل الإشعار
            if let d = Reminders.shortAdhkar("morning").first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("هكذا يصلك الإشعار").rawhText(12, .semibold).foregroundStyle(app.skin.sub)
                    HStack(alignment: .top, spacing: 10) {
                        AppIconPreview(choice: AppIconChoice.current(), size: 38)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("أذكار الصباح ☀️").rawhText(14, .bold).foregroundStyle(app.skin.text)
                                Spacer()
                                Text("الآن").rawhText(11).foregroundStyle(app.skin.sub)
                            }
                            Text(d.t).rawhText(13).foregroundStyle(app.skin.text).lineLimit(4)
                        }
                    }
                    .padding(12)
                    .surface(20, skin: app.skin)
                }
            }
            Text("أوقات الأذكار والصلاة محسوبة لمدينة \(app.city.n). اضغط على الإشعار ليفتح لك القسم مباشرة.").rawhText(12).foregroundStyle(app.skin.sub).multilineTextAlignment(.center)
        }
        .sensoryFeedback(.selection, trigger: bell)
    }
}

// القبلة
struct QiblaView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var q: QiblaManager
    @State private var aligned = false

    init(city: City) { _q = StateObject(wrappedValue: QiblaManager(city: city)) }

    var body: some View {
        let diff = Self.angleDiff(q.bearing, q.heading)
        let isAligned = q.hasHeading && abs(diff) < 4
        SubScreen(title: "اتجاه القبلة", subtitle: q.usingGPS ? "حسب موقعك الحالي" : "حسب مدينة \(app.city.n) · اسمح بالموقع لدقة أعلى") {
            ZStack {
                // قرص البوصلة يدور عكس اتجاه الجوال
                ZStack {
                    Circle().fill(app.skin.card)
                    Circle().strokeBorder(app.skin.gold.opacity(0.5), lineWidth: 1.2)
                    ForEach(0..<72, id: \.self) { i in
                        Rectangle().fill(app.skin.gold.opacity(i % 6 == 0 ? 0.8 : 0.3))
                            .frame(width: i % 6 == 0 ? 2 : 1, height: i % 6 == 0 ? 12 : 6)
                            .offset(y: -128)
                            .rotationEffect(.degrees(Double(i) * 5))
                    }
                    ForEach(0..<4, id: \.self) { i in
                        Text(["ش", "شر", "ج", "غ"][i]).rawhText(14, .bold).foregroundStyle(i == 0 ? app.skin.gold : app.skin.sub)
                            .offset(y: -104).rotationEffect(.degrees(Double(i) * 90))
                    }
                    // مؤشر القبلة على القرص
                    VStack(spacing: 2) {
                        KaabaIcon(size: 24)
                        Capsule().fill(LinearGradient(colors: [app.skin.goldLight, app.skin.gold], startPoint: .top, endPoint: .bottom)).frame(width: 4, height: 70)
                    }
                    .offset(y: -55)
                    .rotationEffect(.degrees(q.bearing))
                }
                .frame(width: 290, height: 290)
                .rotationEffect(.degrees(-q.heading))
                .animation(.easeOut(duration: 0.25), value: q.heading)

                Image(systemName: "location.north.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(isAligned ? app.skin.green : app.skin.text)
                    .offset(y: -168)
                    .symbolEffect(.bounce, value: aligned)
                Circle().fill(app.skin.gold).frame(width: 12, height: 12)
            }
            .frame(height: 360)
            .onChange(of: isAligned) { _, v in if v { aligned.toggle() } }
            .sensoryFeedback(.success, trigger: aligned)

            Text(isAligned ? "أنت متجه إلى القبلة" : (q.hasHeading ? "أدر جوالك حتى يتطابق السهم مع الكعبة" : "البوصلة غير متاحة، القبلة على بُعد \(AR.n(Int(q.bearing)))° من الشمال"))
                .rawhText(16, .semibold)
                .foregroundStyle(isAligned ? app.skin.green : app.skin.text)
                .multilineTextAlignment(.center)
            Text("زاوية القبلة \(AR.n(Int(q.bearing.rounded())))° من الشمال الحقيقي").rawhText(12).foregroundStyle(app.skin.sub)
            Text("ضع الجوال مسطّحًا وبعيدًا عن المعادن").rawhText(12).foregroundStyle(app.skin.sub)
        }
        .onAppear { q.start() }
        .onDisappear { q.stop() }
    }

    static func angleDiff(_ a: Double, _ b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
}

// المحفوظة
struct FavoritesView: View {
    @EnvironmentObject var app: AppState
    @State private var share: CatDhikr? = nil
    var body: some View {
        let favs = DB.allDhikr.filter { app.s.favorites.contains($0.dhikr.id) }
        SubScreen(title: "المحفوظة", subtitle: favs.isEmpty ? "اضغط علامة الحفظ تحت أي ذكر ليظهر هنا" : nil) {
            if favs.isEmpty {
                Image(systemName: "bookmark").font(.system(size: 50)).foregroundStyle(app.skin.gold.opacity(0.5)).padding(40)
            }
            ForEach(favs) { pair in
                VStack(alignment: .leading, spacing: 6) {
                    Text(pair.cat.t).rawhText(12, .semibold).foregroundStyle(app.skin.gold)
                    DhikrCard(dhikr: pair.dhikr, cat: pair.cat, onTap: { app.tap(pair.dhikr, in: pair.cat) }, onShare: { share = pair })
                }
            }
        }
        .sheet(item: $share) { s in ShareSheet(dhikr: s.dhikr, cat: s.cat).environmentObject(app) }
    }
}

// البحث
struct SearchView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var q = ""
    @State private var open: AdhkarCategory? = nil
    var results: [CatDhikr] {
        let n = AR.normalize(q.trimmingCharacters(in: .whitespaces))
        guard n.count >= 2 else { return [] }
        return DB.allDhikr.filter { p in
            AR.normalize(p.dhikr.t + " " + (p.dhikr.h ?? "") + " " + (p.dhikr.f ?? "") + " " + p.cat.t).contains(n)
        }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if q.count < 2 {
                            Text("ابحث بكلمة من الذكر، ولا يلزمك التشكيل").rawhText(14).foregroundStyle(app.skin.sub).padding(.top, 20)
                        } else if results.isEmpty {
                            Text("لا نتائج").rawhText(14).foregroundStyle(app.skin.sub).padding(.top, 20)
                        }
                        ForEach(results) { p in
                            Button { open = p.cat } label: {
                                Card {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(p.cat.t).rawhText(12, .semibold).foregroundStyle(app.skin.gold)
                                        Text(p.dhikr.t).rawhText(16).foregroundStyle(app.skin.text).lineLimit(3).multilineTextAlignment(.leading)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
            .searchable(text: $q, placement: .navigationBarDrawer(displayMode: .always), prompt: "ابحث في الأذكار")
            .navigationTitle("البحث")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("إغلاق") { dismiss() } } }
            .fullScreenCover(item: $open) { c in ReaderView(cat: c).environmentObject(app) }
        }
        .preferredColorScheme(app.skin.scheme)
    }
}

// اختيار أيقونة التطبيق
struct AppIconPicker: View {
    @EnvironmentObject var app: AppState
    @State private var current: AppIconChoice = .emerald
    @State private var tick = 0
    @State private var failed = false
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(AppIconChoice.allCases) { c in
                    Button {
                        guard c != current, UIApplication.shared.supportsAlternateIcons else { return }
                        tick += 1
                        UIApplication.shared.setAlternateIconName(c.assetName) { err in
                            DispatchQueue.main.async {
                                if err == nil { withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { current = c } } else { failed = true }
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            AppIconPreview(choice: c, size: 66)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 66 * 0.2237 + 4, style: .continuous)
                                        .strokeBorder(current == c ? app.skin.gold : Color.clear, lineWidth: 2.5)
                                        .padding(-4)
                                )
                                .scaleEffect(current == c ? 1.04 : 1)
                            Text(c.title).rawhText(12.5, .semibold).foregroundStyle(current == c ? app.skin.gold : app.skin.text)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(PressScale())
                }
            }
            .padding(.horizontal, 4)
        }
        .sensoryFeedback(.success, trigger: tick)
        .onAppear { current = AppIconChoice.current() }
        .alert("تعذّر تغيير الأيقونة", isPresented: $failed) { Button("حسنًا", role: .cancel) {} }
    }
}

// الإعدادات
struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionTitle(title: "المظهر")
                        HStack(spacing: 12) {
                            ForEach(Skin.allCases) { k in
                                Button { withAnimation(.easeInOut(duration: 0.35)) { app.s.skin = k } } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LinearGradient(colors: [k.bg, k.bg2], startPoint: .top, endPoint: .bottom))
                                            ArchShape(shoulder: 0.38).stroke(k.gold, lineWidth: 2).frame(width: 34, height: 46)
                                            StarBurst().fill(k.gold).frame(width: 9, height: 9).offset(y: -30)
                                        }
                                        .frame(height: 96)
                                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(app.s.skin == k ? app.skin.gold : app.skin.line, lineWidth: app.s.skin == k ? 2.5 : 0.8))
                                        Text(k.name).rawhText(14, .semibold).foregroundStyle(app.skin.text)
                                        Image(systemName: app.s.skin == k ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(app.s.skin == k ? app.skin.gold : app.skin.sub)
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                            }
                        }

                        SectionTitle(title: "أيقونة التطبيق")
                        AppIconPicker()

                        SectionTitle(title: "حجم النص")
                        Card {
                            VStack(spacing: 12) {
                                Text("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ").rawhText(21 * app.s.textScale).foregroundStyle(app.skin.text).frame(maxWidth: .infinity)
                                HStack {
                                    Image(systemName: "textformat.size.smaller").foregroundStyle(app.skin.sub)
                                    Slider(value: Binding(get: { app.s.textScale }, set: { app.s.textScale = $0 }), in: 0.85...1.45, step: 0.05).tint(app.skin.gold)
                                    Image(systemName: "textformat.size.larger").foregroundStyle(app.skin.sub)
                                }
                            }
                        }

                        SectionTitle(title: "المدينة")
                        Card(padding: 6) {
                            Picker("المدينة", selection: Binding(get: { app.s.cityId }, set: { app.s.cityId = $0; Reminders.schedule(app.s) })) {
                                ForEach(DB.data.cities) { Text($0.n).tag($0.id) }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 130)
                        }
                        Text("تُستخدم لحساب مواقيت الصلاة وأوقات التذكير").rawhText(12).foregroundStyle(app.skin.sub)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("المظهر والإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("تم") { dismiss() }.tint(app.skin.gold) } }
        }
        .preferredColorScheme(app.skin.scheme)
    }
}


// MARK: - النشاط المباشر: تشغيل وإيقاف العدّ التنازلي للصلاة

enum PrayerLive {
    static var enabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }
    static var isRunning: Bool { !Activity<PrayerActivityAttributes>.activities.isEmpty }

    static func state(for city: City, now: Date = Date()) -> PrayerActivityAttributes.ContentState {
        let n = PrayerTimes.next(after: now, city: city)
        return .init(key: n.key, name: PrayerTimes.names[n.key] ?? "", start: now, date: n.date)
    }

    static func start(city: City) {
        let s = state(for: city)
        Task {
            for a in Activity<PrayerActivityAttributes>.activities { await a.end(nil, dismissalPolicy: .immediate) }
            let content = ActivityContent(state: s, staleDate: s.date.addingTimeInterval(20 * 60))
            _ = try? Activity.request(attributes: PrayerActivityAttributes(city: city.n), content: content)
        }
    }

    /// إذا دخل وقت الصلاة ننتقل للصلاة التي بعدها
    static func refresh(city: City) {
        let s = state(for: city)
        Task {
            for a in Activity<PrayerActivityAttributes>.activities where a.content.state.date < Date() || a.attributes.city != city.n {
                if a.attributes.city != city.n {
                    await a.end(nil, dismissalPolicy: .immediate)
                    start(city: city)
                    return
                }
                await a.update(ActivityContent(state: s, staleDate: s.date.addingTimeInterval(20 * 60)))
            }
        }
    }

    static func stop() {
        Task { for a in Activity<PrayerActivityAttributes>.activities { await a.end(nil, dismissalPolicy: .immediate) } }
    }
}

// MARK: - Siri والاختصارات

enum CategoryOption: String, AppEnum {
    case morning, evening, prayer, sleep, wake, ruqya, distress, daily

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "قسم الأذكار"
    static var caseDisplayRepresentations: [CategoryOption: DisplayRepresentation] = [
        .morning: "أذكار الصباح", .evening: "أذكار المساء", .prayer: "أذكار بعد الصلاة", .sleep: "أذكار النوم",
        .wake: "أذكار الاستيقاظ", .ruqya: "الرقية الشرعية", .distress: "أذكار الهمّ والكرب", .daily: "أذكار اليوم والليلة"
    ]
}

struct OpenAdhkarIntent: AppIntent {
    static var title: LocalizedStringResource = "افتح الأذكار"
    static var description = IntentDescription("يفتح قسمًا من الأذكار في رَوْح")
    static var openAppWhenRun: Bool = true
    @Parameter(title: "القسم", default: .morning)
    var category: CategoryOption

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationRouter.shared.openCat = category.rawValue
        return .result()
    }
}

struct NextPrayerIntent: AppIntent {
    static var title: LocalizedStringResource = "الصلاة القادمة"
    static var description = IntentDescription("يخبرك بالصلاة القادمة والوقت المتبقي")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        var cityId = "riyadh"
        if let d = UserDefaults.standard.data(forKey: "rawh.saved.v1"), let s = try? JSONDecoder().decode(Saved.self, from: d) { cityId = s.cityId }
        let city = DB.city(cityId)
        let n = PrayerTimes.next(after: Date(), city: city)
        let name = PrayerTimes.names[n.key] ?? ""
        let left = HomeView.left(n.date.timeIntervalSinceNow)
        return .result(dialog: "صلاة \(name) الساعة \(AR.timeF.string(from: n.date))، \(left)")
    }
}

struct OpenSebhaIntent: AppIntent {
    static var title: LocalizedStringResource = "افتح السبحة"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationRouter.shared.tab = 2
        return .result()
    }
}

struct RawhShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenAdhkarIntent(), phrases: [
            "افتح \(\.$category) في \(.applicationName)",
            "\(\.$category) في \(.applicationName)",
            "أذكار \(.applicationName)"
        ], shortTitle: "الأذكار", systemImageName: "book.fill")
        AppShortcut(intent: NextPrayerIntent(), phrases: [
            "كم باقي على الصلاة في \(.applicationName)",
            "الصلاة القادمة في \(.applicationName)"
        ], shortTitle: "الصلاة القادمة", systemImageName: "clock.fill")
        AppShortcut(intent: OpenSebhaIntent(), phrases: [
            "افتح السبحة في \(.applicationName)",
            "سبحة \(.applicationName)"
        ], shortTitle: "السبحة", systemImageName: "circle.hexagongrid.fill")
    }
}


// MARK: - صوت التنبيهات: الجوال ينطق «أذكار الصباح، أثابكم الله»

enum VoiceAlerts {
    static let version = "v1"   // غيّره لو تغيّرت العبارات عشان تنعاد تسجيلها

    static let phrases: [(key: String, text: String)] = [
        ("morning", "أذكار الصباح، أثابكم الله"),
        ("evening", "أذكار المساء، أثابكم الله"),
        ("sleep", "أذكار النوم، تصبحون على خير، أثابكم الله"),
        ("daily", "اذكروا الله، أثابكم الله"),
        ("fajr", "حان الآن وقت صلاة الفجر، أثابكم الله"),
        ("dhuhr", "حان الآن وقت صلاة الظهر، أثابكم الله"),
        ("asr", "حان الآن وقت صلاة العصر، أثابكم الله"),
        ("maghrib", "حان الآن وقت صلاة المغرب، أثابكم الله"),
        ("isha", "حان الآن وقت صلاة العشاء، أثابكم الله"),
        ("fast", "تذكير بالصيام غدًا، أثابكم الله"),
        ("white", "تذكير بصيام الأيام البيض، أثابكم الله")
    ]

    static func fileName(_ key: String) -> String { "rawh-\(version)-\(key).caf" }

    /// iOS يبحث عن أصوات التنبيهات في Library/Sounds داخل التطبيق
    static var soundsDir: URL {
        let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let dir = lib.appendingPathComponent("Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static func fileURL(_ key: String) -> URL { soundsDir.appendingPathComponent(fileName(key)) }
    static func exists(_ key: String) -> Bool { FileManager.default.fileExists(atPath: fileURL(key).path) }

    /// صوت التنبيه: العبارة المسجّلة إن وُجدت وكان الصوت مفعّلًا، وإلا النغمة العادية
    static func sound(_ key: String, enabled: Bool) -> UNNotificationSound {
        guard enabled, exists(key) else { return .default }
        return UNNotificationSound(named: UNNotificationSoundName(fileName(key)))
    }

    static var arabicVoice: AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("ar") }
        // الأفضل جودةً أولًا، ثم السعودي
        return voices.sorted { a, b in
            if a.quality != b.quality { return a.quality.rawValue > b.quality.rawValue }
            return a.language == "ar-SA" && b.language != "ar-SA"
        }.first ?? AVSpeechSynthesisVoice(language: "ar-SA")
    }

    // تسجيل العبارات بالتتابع
    private static let synth = AVSpeechSynthesizer()
    private static var queue: [(key: String, text: String)] = []
    private static var output: AVAudioFile?
    private static var waiters: [() -> Void] = []
    private static var busy = false

    /// يسجّل العبارات الناقصة (أول مرة فقط)، ثم ينادي done
    static func prepare(force: Bool = false, done: @escaping () -> Void) {
        DispatchQueue.main.async {
            // إذا التسجيل شغّال، ننتظر نهايته بدل ما نضيّع الطلب
            if busy { waiters.append(done); return }
            queue = phrases.filter { force || !exists($0.key) }
            if queue.isEmpty || arabicVoice == nil { done(); return }
            busy = true
            waiters = [done]
            next()
        }
    }

    private static func next() {
        guard !queue.isEmpty else {
            busy = false
            let w = waiters; waiters = []
            w.forEach { $0() }
            return
        }
        let item = queue.removeFirst()
        let url = fileURL(item.key)
        try? FileManager.default.removeItem(at: url)
        output = nil
        let u = AVSpeechUtterance(string: item.text)
        u.voice = arabicVoice
        u.rate = 0.44
        u.pitchMultiplier = 1.0
        u.preUtteranceDelay = 0.15
        u.postUtteranceDelay = 0.2
        var ended = false
        synth.write(u) { buffer in
            guard let pcm = buffer as? AVAudioPCMBuffer else { return }
            if pcm.frameLength == 0 {
                if !ended { ended = true; output = nil; DispatchQueue.main.async { next() } }
                return
            }
            if output == nil {
                output = try? AVAudioFile(forWriting: url, settings: pcm.format.settings,
                                          commonFormat: pcm.format.commonFormat, interleaved: pcm.format.isInterleaved)
            }
            try? output?.write(from: pcm)
        }
    }

    // تجربة الصوت داخل التطبيق
    private static var player: AVAudioPlayer?
    static func preview(_ key: String) {
        let play = {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try? AVAudioSession.sharedInstance().setActive(true)
            player = try? AVAudioPlayer(contentsOf: fileURL(key))
            player?.play()
        }
        if exists(key) { play() } else { prepare { if exists(key) { play() } } }
    }
}

/// صف تجربة الأصوات في شاشة التذكيرات
struct VoicePreviewRow: View {
    @EnvironmentObject var app: AppState
    @State private var t = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("اسمع صوت كل تنبيه").rawhText(12, .semibold).foregroundStyle(app.skin.sub)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VoiceAlerts.phrases, id: \.key) { p in
                        Button {
                            t += 1
                            VoiceAlerts.preview(p.key)
                        } label: {
                            Label(Self.short(p.key), systemImage: "speaker.wave.2.fill")
                                .rawhText(13, .semibold)
                                .foregroundStyle(app.skin.text)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .glassCapsule(skin: app.skin, fallback: app.skin.card)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: t)
    }
    static func short(_ key: String) -> String {
        switch key {
        case "morning": return "الصباح"
        case "evening": return "المساء"
        case "sleep": return "النوم"
        case "daily": return "خلال اليوم"
        case "fast": return "الصيام"
        case "white": return "الأيام البيض"
        default: return PrayerTimes.names[key] ?? key
        }
    }
}


// MARK: - المقدمة

struct IntroView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var tick = 0

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 0) {
                HStack {
                    Text("\(AR.n(page + 1)) / \(AR.n(3))").rawhText(13).foregroundStyle(app.skin.sub)
                    Spacer()
                    Button("تخطَّ") { finish() }.foregroundStyle(app.skin.gold)
                }
                .padding(.horizontal, 22).padding(.top, 14)

                TabView(selection: $page) {
                    welcome.tag(0)
                    features.tag(1)
                    setup.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    tick += 1
                    if page < 2 { withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { page += 1 } } else { finish() }
                } label: {
                    Label(page < 2 ? "التالي" : "ابدأ رحلتك", systemImage: page < 2 ? "chevron.left" : "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GoldButtonStyle(skin: app.skin))
                .padding(.horizontal, 22).padding(.bottom, 24)
                .sensoryFeedback(.selection, trigger: tick)
            }
        }
        .preferredColorScheme(app.skin.scheme)
    }

    private func finish() {
        app.s.introSeen = true
        VoiceAlerts.prepare { Reminders.requestAndSchedule(app.s) }
        dismiss()
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            Spacer()
            Emblem(size: 170, animate: true)
            Text("رَوْح").rawhText(44, .bold).foregroundStyle(app.skin.text)
            Text("﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾").rawhText(22, .medium).foregroundStyle(app.skin.gold)
            Text("أذكارك اليومية من القرآن والسنة الصحيحة، في تجربة هادئة تليق بها.")
                .rawhText(15).foregroundStyle(app.skin.sub).multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer()
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text("كل ما يحتاجه وِردك").rawhText(28, .bold).foregroundStyle(app.skin.text)
            Text("مصمَّم ليجمع قلبك، لا ليشغلك.").rawhText(14).foregroundStyle(app.skin.sub)
            feature("clock.fill", "وِرد في وقته", "يظهر لك وِرد الصباح أو المساء حسب مواقيت مدينتك.")
            feature("hand.tap.fill", "العدّ باللمس", "اضغط على الذكر نفسه، ويهتز جوالك مع كل عدّة.")
            feature("smallcircle.filled.circle", "وضع الخلوة", "ذكر واحد أمامك بخط كبير، ولا شيء غيره.")
            feature("book.fill", "القرآن الكريم", "المصحف كاملاً بالرسم العثماني وبصوت العفاسي.")
            feature("bell.fill", "تذكيرات حقيقية", "إشعارات للأذكار والصلاة والصيام.")
            Spacer()
        }
        .padding(.horizontal, 26)
    }

    private func feature(_ s: String, _ t: String, _ d: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: s)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(app.skin.gold)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(app.skin.gold.opacity(0.14)))
                .symbolEffect(.bounce, value: page)
            VStack(alignment: .leading, spacing: 3) {
                Text(t).rawhText(16, .bold).foregroundStyle(app.skin.text)
                Text(d).rawhText(13).foregroundStyle(app.skin.sub).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text("اجعله لك").rawhText(28, .bold).foregroundStyle(app.skin.text)
            Text("تقدر تغيّر هذا لاحقًا من الإعدادات.").rawhText(14).foregroundStyle(app.skin.sub)
            Text("مدينتك").rawhText(14, .semibold).foregroundStyle(app.skin.gold)
            Picker("المدينة", selection: Binding(get: { app.s.cityId }, set: { app.s.cityId = $0 })) {
                ForEach(DB.data.cities) { Text($0.n).tag($0.id) }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .surface(16, skin: app.skin)
            Text("المظهر").rawhText(14, .semibold).foregroundStyle(app.skin.gold)
            HStack(spacing: 10) {
                ForEach(Skin.allCases) { k in
                    Button { withAnimation(.easeInOut(duration: 0.35)) { app.s.skin = k } } label: {
                        VStack(spacing: 6) {
                            Circle().fill(LinearGradient(colors: [k.bg, k.bg2], startPoint: .top, endPoint: .bottom))
                                .overlay(StarBurst().fill(k.gold).padding(14))
                                .overlay(Circle().strokeBorder(app.s.skin == k ? app.skin.gold : app.skin.line, lineWidth: app.s.skin == k ? 2.5 : 1))
                                .frame(width: 58, height: 58)
                            Text(k.name).rawhText(13, .semibold).foregroundStyle(app.skin.text)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 26)
    }
}

// MARK: - التطبيق

struct RootView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.scenePhase) private var phase
    @ObservedObject private var router = NotificationRouter.shared
    @State private var tab = 0
    @State private var showIntro = false
    @State private var splash = true

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("الرئيسية", systemImage: "house.fill") }.tag(0)
            QuranView()
                .tabItem { Label("القرآن", systemImage: "book.fill") }.tag(1)
            SebhaView()
                .tabItem { Label("السبحة", systemImage: "circle.hexagongrid.fill") }.tag(2)
            StatsView()
                .tabItem { Label("إنجازي", systemImage: "chart.bar.fill") }.tag(3)
            MoreView()
                .tabItem { Label("المزيد", systemImage: "square.grid.2x2.fill") }.tag(4)
        }
        .tint(app.skin.gold)
        .minimizingTabBar()
        .sensoryFeedback(.selection, trigger: tab)
        .preferredColorScheme(app.skin.scheme)
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar_SA"))
        .onAppear {
            styleBars()
            if !app.s.introSeen { showIntro = true } else { VoiceAlerts.prepare { Reminders.requestAndSchedule(app.s) } }
        }
        .onChange(of: app.s.skin) { _, _ in styleBars() }
        .onChange(of: phase) { _, p in
            if p == .active {
                app.now = Date(); app.rollDay()
                if PrayerLive.isRunning { PrayerLive.refresh(city: app.city) }
            }
        }
        .onOpenURL { url in router.handle(url) }
        .onChange(of: router.tab) { _, t in
            if let t { withAnimation { tab = t }; router.tab = nil }
        }
        .onChange(of: router.openCat) { _, c in if c != nil { tab = 0 } }
        .overlay {
            if splash && app.s.introSeen {
                SplashView { withAnimation(.easeInOut(duration: 0.5)) { splash = false } }
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .fullScreenCover(isPresented: $showIntro) { IntroView().environmentObject(app) }
        .sheet(item: Binding(get: { router.openCat.flatMap { DB.cat($0) } }, set: { if $0 == nil { router.openCat = nil } })) { c in
            ReaderView(cat: c).environmentObject(app)
        }
    }

    private func styleBars() {
        let k = app.skin
        // iOS 26: الأشرطة زجاج سائل من النظام نفسه، لا نلوّنها
        if #available(iOS 26.0, *) { return }
        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundColor = UIColor(k.bg2).withAlphaComponent(0.92)
        tab.shadowColor = UIColor(k.gold).withAlphaComponent(0.25)
        let normal = UIColor(k.text).withAlphaComponent(0.5)
        for layout in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            layout.normal.iconColor = normal
            layout.normal.titleTextAttributes = [.foregroundColor: normal]
            layout.selected.iconColor = UIColor(k.gold)
            layout.selected.titleTextAttributes = [.foregroundColor: UIColor(k.gold)]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor(k.text)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(k.text)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(k.gold)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(k.gold)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(k.onGold)], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(k.text)], for: .normal)
    }
}

@main
struct RawhApp: App {
    @StateObject private var app = AppState()
    init() { UNUserNotificationCenter.current().delegate = NotificationRouter.shared }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
        }
    }
}

// ===== WIDGET =====
// رَوْح — الودجت والنشاط المباشر
import WidgetKit
import SwiftUI
import AppIntents
import ActivityKit

// MARK: - اختيار المدينة في إعدادات الودجت

enum CityOption: String, AppEnum {
    case riyadh, makkah, madinah, jeddah, dammam, abha, tabuk, hail, buraydah, jazan

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "المدينة"
    static var caseDisplayRepresentations: [CityOption: DisplayRepresentation] = [
        .riyadh: "الرياض", .makkah: "مكة المكرمة", .madinah: "المدينة المنورة", .jeddah: "جدة", .dammam: "الدمام",
        .abha: "أبها", .tabuk: "تبوك", .hail: "حائل", .buraydah: "بريدة", .jazan: "جازان"
    ]
}

struct PrayerWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "مدينة المواقيت"
    static var description = IntentDescription("اختر المدينة لحساب مواقيت الصلاة")
    @Parameter(title: "المدينة", default: .riyadh)
    var city: CityOption
}

// MARK: - ألوان الودجت (مظهر زمرّد)

enum WTheme {
    static let top = Color(hex: 0x14473A)
    static let bottom = Color(hex: 0x062019)
    static let gold = Color(hex: 0xE2C88E)
    static let text = Color(hex: 0xF4ECD8)
    static let sub = Color(hex: 0xF4ECD8, opacity: 0.62)
    static var background: some View {
        ZStack {
            LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [gold.opacity(0.16), .clear], center: .topTrailing, startRadius: 4, endRadius: 220)
            SixStar().stroke(gold.opacity(0.08), lineWidth: 1.2).frame(width: 190, height: 190).offset(x: 70, y: -40)
        }
    }
}

// MARK: - ودجت الصلاة القادمة

struct PrayerEntry: TimelineEntry {
    let date: Date
    let city: City
    let times: PrayerTimes
    let nextKey: String
    let nextDate: Date

    static func make(_ d: Date, _ city: City) -> PrayerEntry {
        let n = PrayerTimes.next(after: d, city: city)
        return PrayerEntry(date: d, city: city, times: PrayerTimes.compute(for: d, city: city), nextKey: n.key, nextDate: n.date)
    }
}

struct PrayerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry { .make(Date(), DB.city("riyadh")) }
    func snapshot(for configuration: PrayerWidgetIntent, in context: Context) async -> PrayerEntry {
        .make(Date(), DB.city(configuration.city.rawValue))
    }
    func timeline(for configuration: PrayerWidgetIntent, in context: Context) async -> Timeline<PrayerEntry> {
        let city = DB.city(configuration.city.rawValue)
        var entries: [PrayerEntry] = [.make(Date(), city)]
        var t = Date()
        // سطر جديد بعد كل صلاة، ليوم كامل
        for _ in 0..<6 {
            let n = PrayerTimes.next(after: t, city: city)
            t = n.date.addingTimeInterval(1)
            entries.append(.make(t, city))
        }
        return Timeline(entries: entries, policy: .after(t))
    }
}

struct PrayerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: PrayerEntry
    private var name: String { PrayerTimes.names[entry.nextKey] ?? "" }
    private var symbol: String { PrayerTimes.symbols[entry.nextKey] ?? "sun.max.fill" }

    var body: some View {
        content
            .environment(\.layoutDirection, .rightToLeft)
            .widgetURL(RawhLink.prayer)
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .accessoryInline:
            Label("\(name) \(AR.timeF.string(from: entry.nextDate))", systemImage: symbol)
                .containerBackground(for: .widget) { Color.clear }
        case .accessoryCircular:
            VStack(spacing: 1) {
                Image(systemName: symbol).font(.system(size: 13, weight: .semibold))
                Text(name).font(.system(size: 11, weight: .bold)).minimumScaleFactor(0.7)
                Text(entry.nextDate, style: .timer).font(.system(size: 10, weight: .medium)).monospacedDigit().multilineTextAlignment(.center)
            }
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Label("الصلاة القادمة", systemImage: symbol).font(.system(size: 12, weight: .semibold))
                Text("\(name) · \(AR.timeF.string(from: entry.nextDate))").font(.system(size: 15, weight: .bold))
                Text(entry.nextDate, style: .timer).font(.system(size: 13)).monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { Color.clear }
        case .systemMedium:
            HStack(spacing: 14) {
                nextBlock
                Rectangle().fill(WTheme.gold.opacity(0.25)).frame(width: 0.8)
                VStack(spacing: 4) {
                    ForEach(["fajr", "dhuhr", "asr", "maghrib", "isha"], id: \.self) { k in
                        HStack {
                            Image(systemName: PrayerTimes.symbols[k] ?? "sun.max").font(.system(size: 11)).frame(width: 16)
                            Text(PrayerTimes.names[k] ?? "").font(.system(size: 12.5, weight: k == entry.nextKey ? .bold : .regular))
                            Spacer()
                            Text(AR.timeF.string(from: entry.times.date(k, on: entry.date))).font(.system(size: 12.5, weight: k == entry.nextKey ? .bold : .regular))
                        }
                        .foregroundStyle(k == entry.nextKey ? WTheme.gold : WTheme.text)
                    }
                }
            }
            .containerBackground(for: .widget) { WTheme.background }
        default:
            nextBlock
                .containerBackground(for: .widget) { WTheme.background }
        }
    }

    private var nextBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                SixStar().stroke(WTheme.gold, lineWidth: 1.4).frame(width: 15, height: 15)
                Text(entry.city.n).font(.system(size: 11, weight: .medium)).foregroundStyle(WTheme.sub)
            }
            Spacer(minLength: 2)
            Image(systemName: symbol).font(.system(size: 20, weight: .medium)).foregroundStyle(WTheme.gold).symbolRenderingMode(.hierarchical)
            Text(name).font(.system(size: 24, weight: .bold)).foregroundStyle(WTheme.text)
            Text(AR.timeF.string(from: entry.nextDate)).font(.system(size: 13, weight: .semibold)).foregroundStyle(WTheme.gold)
            Text(entry.nextDate, style: .timer).font(.system(size: 13, weight: .medium)).monospacedDigit().foregroundStyle(WTheme.sub)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrayerWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "RawhPrayer", intent: PrayerWidgetIntent.self, provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("الصلاة القادمة")
        .description("الصلاة القادمة مع عدّ تنازلي، ومواقيت اليوم.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - ودجت ذكر الساعة

struct DhikrEntry: TimelineEntry {
    let date: Date
    let item: DhikrPool.Item
}

struct DhikrProvider: TimelineProvider {
    func placeholder(in context: Context) -> DhikrEntry { DhikrEntry(date: Date(), item: DhikrPool.item(at: Date())) }
    func getSnapshot(in context: Context, completion: @escaping (DhikrEntry) -> Void) {
        completion(DhikrEntry(date: Date(), item: DhikrPool.item(at: Date())))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DhikrEntry>) -> Void) {
        let cal = Calendar.current
        let now = Date()
        let hour = cal.dateInterval(of: .hour, for: now)?.start ?? now
        var entries: [DhikrEntry] = []
        for i in 0..<12 {
            let d = i == 0 ? now : (cal.date(byAdding: .hour, value: i, to: hour) ?? now)
            entries.append(DhikrEntry(date: d, item: DhikrPool.item(at: d)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct DhikrWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: DhikrEntry
    var body: some View {
        Group {
            if family == .accessoryRectangular {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.item.title).font(.system(size: 11, weight: .semibold))
                    Text(entry.item.text).font(.system(size: 13, weight: .medium)).lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .containerBackground(for: .widget) { Color.clear }
            } else {
                VStack(spacing: family == .systemLarge ? 14 : 8) {
                    HStack(spacing: 6) {
                        Rectangle().fill(WTheme.gold.opacity(0.5)).frame(height: 0.8)
                        SixStar().stroke(WTheme.gold, lineWidth: 1.3).frame(width: 14, height: 14)
                        Rectangle().fill(WTheme.gold.opacity(0.5)).frame(height: 0.8)
                    }
                    .frame(width: 120)
                    Text(entry.item.text)
                        .font(.system(size: family == .systemLarge ? 24 : 17, weight: .medium))
                        .foregroundStyle(WTheme.text)
                        .multilineTextAlignment(.center)
                        .lineSpacing(family == .systemLarge ? 10 : 5)
                        .minimumScaleFactor(0.6)
                    Text(entry.item.title).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(WTheme.gold)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(for: .widget) { WTheme.background }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(entry.item.cat.map { RawhLink.category($0) } ?? RawhLink.sebha)
    }
}

struct DhikrWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RawhDhikr", provider: DhikrProvider()) { entry in
            DhikrWidgetView(entry: entry)
        }
        .configurationDisplayName("ذكر الساعة")
        .description("ذكر أو حديث يتجدّد كل ساعة.")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular])
    }
}

// MARK: - النشاط المباشر: عدّ تنازلي للصلاة على شاشة القفل و Dynamic Island

struct PrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            HStack(spacing: 14) {
                ZStack {
                    SixStar().stroke(WTheme.gold, lineWidth: 1.6)
                    Image(systemName: PrayerTimes.symbols[context.state.key] ?? "sun.max.fill")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(WTheme.gold)
                }
                .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("صلاة \(context.state.name)").font(.system(size: 18, weight: .bold)).foregroundStyle(WTheme.text)
                    Text("\(context.attributes.city) · \(AR.timeF.string(from: context.state.date))").font(.system(size: 13)).foregroundStyle(WTheme.sub)
                }
                Spacer()
                Text(timerInterval: context.state.start...context.state.date, countsDown: true)
                    .font(.system(size: 26, weight: .bold)).monospacedDigit()
                    .foregroundStyle(WTheme.gold)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 96)
            }
            .padding(16)
            .environment(\.layoutDirection, .rightToLeft)
            .activityBackgroundTint(Color(hex: 0x0A2620))
            .activitySystemActionForegroundColor(WTheme.gold)
            .widgetURL(RawhLink.prayer)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.name, systemImage: PrayerTimes.symbols[context.state.key] ?? "sun.max.fill")
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(WTheme.gold)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.start...context.state.date, countsDown: true)
                        .font(.system(size: 16, weight: .bold)).monospacedDigit().foregroundStyle(WTheme.text)
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.city) · الأذان \(AR.timeF.string(from: context.state.date))")
                        .font(.system(size: 13)).foregroundStyle(WTheme.sub)
                }
            } compactLeading: {
                Image(systemName: PrayerTimes.symbols[context.state.key] ?? "sun.max.fill").foregroundStyle(WTheme.gold)
            } compactTrailing: {
                Text(timerInterval: context.state.start...context.state.date, countsDown: true)
                    .monospacedDigit().font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WTheme.gold)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: PrayerTimes.symbols[context.state.key] ?? "sun.max.fill").foregroundStyle(WTheme.gold)
            }
            .widgetURL(RawhLink.prayer)
            .keylineTint(WTheme.gold)
        }
    }
}

@main
struct RawhWidgets: WidgetBundle {
    var body: some Widget {
        PrayerWidget()
        DhikrWidget()
        PrayerLiveActivity()
    }
}
