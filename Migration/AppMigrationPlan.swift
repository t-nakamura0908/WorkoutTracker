import SwiftData

// MARK: - V1: 初期スキーマ

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self
    ]
}

// MARK: - V2: インターバル・完了フラグを追加

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] = [
        WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self
    ]
}

// MARK: - V3: コンディション記録・テンプレートを追加

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] = [
        WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self,
        DailyCondition.self, WorkoutTemplate.self, TemplateExercise.self
    ]
}

// MARK: - マイグレーションプラン

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self, SchemaV2.self, SchemaV3.self
    ]
    static var stages: [MigrationStage] = [
        .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self),
        .lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)
    ]
}
