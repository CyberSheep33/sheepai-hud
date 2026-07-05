import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var userId: String = ""
    @State private var systemToken: String = ""
    @State private var showSaved: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("设置")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 24)

            // Form
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("用户 ID (new-api-user)")
                            .font(.headline)
                        TextField("输入你的账户 ID", text: $userId)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("系统令牌 (Authorization)")
                            .font(.headline)
                        SecureField("输入你的系统令牌", text: $systemToken)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("API 凭证")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("凭证安全存储在你的设备 App Group 中，仅用于调用小羊AI API。")
                            .foregroundColor(.secondary)
                        if showSaved {
                            Text("✅ 凭证已保存")
                                .foregroundColor(.green)
                        }
                    }
                }

                Section {
                    Button(action: saveAction) {
                        HStack {
                            Spacer()
                            Text("保存凭证")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(userId.trimmingCharacters(in: .whitespaces).isEmpty ||
                             systemToken.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .formStyle(.grouped)
        }
        .onAppear {
            userId = viewModel.savedUserId
            systemToken = viewModel.savedSystemToken
        }
    }

    private func saveAction() {
        let cleanUserId = userId.trimmingCharacters(in: .whitespaces)
        let cleanToken = systemToken.trimmingCharacters(in: .whitespaces)
        viewModel.updateCredentials(userId: cleanUserId, systemToken: cleanToken)
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: AppViewModel())
    }
}
#endif
