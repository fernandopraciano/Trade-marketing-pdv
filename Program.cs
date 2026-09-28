using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;

namespace TVLarTradeMarketing
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class MainForm : Form
    {
        private Panel headerPanel;
        private Label lblTitle;
        private Label lblSubtitle;
        private Label lblStatus;
        private TextBox txtLog;
        private Panel inputPanel;
        private Label lblUrlPrompt;
        private TextBox txtRepoUrl;
        private Button btnSaveUrl;
        private Button btnSync;
        private Button btnClose;
        private ProgressBar progressBar;

        private string projectDir;
        private string gitPath;

        public MainForm()
        {
            this.projectDir = AppDomain.CurrentDomain.BaseDirectory;
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = "TVLar Trade Marketing - Sincronizador GitHub";
            this.Size = new Size(650, 520);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.BackColor = Color.FromArgb(248, 250, 252);
            this.Font = new Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point);

            // Header Panel
            headerPanel = new Panel();
            headerPanel.Dock = DockStyle.Top;
            headerPanel.Height = 70;
            headerPanel.BackColor = Color.FromArgb(15, 23, 42); // slate-900

            lblTitle = new Label();
            lblTitle.Text = "TVLar Trade Marketing";
            lblTitle.Font = new Font("Segoe UI", 12F, FontStyle.Bold, GraphicsUnit.Point);
            lblTitle.ForeColor = Color.White;
            lblTitle.Location = new Point(16, 12);
            lblTitle.AutoSize = true;

            lblSubtitle = new Label();
            lblSubtitle.Text = "Sincronizador Automático com o GitHub";
            lblSubtitle.Font = new Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point);
            lblSubtitle.ForeColor = Color.FromArgb(148, 163, 184); // slate-400
            lblSubtitle.Location = new Point(17, 38);
            lblSubtitle.AutoSize = true;

            lblStatus = new Label();
            lblStatus.Text = "Pronto";
            lblStatus.Font = new Font("Segoe UI", 9F, FontStyle.Bold, GraphicsUnit.Point);
            lblStatus.ForeColor = Color.FromArgb(52, 211, 153); // emerald-400
            lblStatus.Location = new Point(440, 24);
            lblStatus.Size = new Size(180, 25);
            lblStatus.TextAlign = ContentAlignment.MiddleRight;

            headerPanel.Controls.Add(lblTitle);
            headerPanel.Controls.Add(lblSubtitle);
            headerPanel.Controls.Add(lblStatus);
            this.Controls.Add(headerPanel);

            // Input Panel for first-time GitHub URL
            inputPanel = new Panel();
            inputPanel.Dock = DockStyle.Top;
            inputPanel.Height = 65;
            inputPanel.BackColor = Color.FromArgb(254, 243, 199); // amber-100
            inputPanel.Visible = false;

            lblUrlPrompt = new Label();
            lblUrlPrompt.Text = "Informe a URL do repositório no GitHub para vincular este projeto:";
            lblUrlPrompt.Font = new Font("Segoe UI", 8.5F, FontStyle.Bold, GraphicsUnit.Point);
            lblUrlPrompt.ForeColor = Color.FromArgb(146, 64, 14);
            lblUrlPrompt.Location = new Point(16, 8);
            lblUrlPrompt.AutoSize = true;

            txtRepoUrl = new TextBox();
            txtRepoUrl.Location = new Point(16, 28);
            txtRepoUrl.Size = new Size(460, 25);
            txtRepoUrl.Font = new Font("Segoe UI", 9F);

            btnSaveUrl = new Button();
            btnSaveUrl.Text = "Vincular";
            btnSaveUrl.Location = new Point(486, 26);
            btnSaveUrl.Size = new Size(130, 28);
            btnSaveUrl.BackColor = Color.FromArgb(180, 83, 9);
            btnSaveUrl.ForeColor = Color.White;
            btnSaveUrl.FlatStyle = FlatStyle.Flat;
            btnSaveUrl.Font = new Font("Segoe UI", 8.5F, FontStyle.Bold);
            btnSaveUrl.Click += new EventHandler(BtnSaveUrl_Click);

            inputPanel.Controls.Add(lblUrlPrompt);
            inputPanel.Controls.Add(txtRepoUrl);
            inputPanel.Controls.Add(btnSaveUrl);
            this.Controls.Add(inputPanel);

            // Progress Bar
            progressBar = new ProgressBar();
            progressBar.Dock = DockStyle.Top;
            progressBar.Height = 4;
            progressBar.Style = ProgressBarStyle.Marquee;
            progressBar.Visible = false;
            this.Controls.Add(progressBar);

            // Log TextBox
            txtLog = new TextBox();
            txtLog.Multiline = true;
            txtLog.ReadOnly = true;
            txtLog.ScrollBars = ScrollBars.Vertical;
            txtLog.BackColor = Color.FromArgb(241, 245, 249); // slate-100
            txtLog.ForeColor = Color.FromArgb(30, 41, 59); // slate-800
            txtLog.Font = new Font("Consolas", 9F, FontStyle.Regular, GraphicsUnit.Point);
            txtLog.Dock = DockStyle.Fill;
            this.Controls.Add(txtLog);

            // Bottom Buttons Panel
            Panel bottomPanel = new Panel();
            bottomPanel.Dock = DockStyle.Bottom;
            bottomPanel.Height = 55;
            bottomPanel.BackColor = Color.White;

            btnSync = new Button();
            btnSync.Text = "Sincronizar Agora";
            btnSync.Size = new Size(160, 34);
            btnSync.Location = new Point(16, 10);
            btnSync.BackColor = Color.FromArgb(0, 114, 188); // TVLar blue
            btnSync.ForeColor = Color.White;
            btnSync.FlatStyle = FlatStyle.Flat;
            btnSync.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            btnSync.Click += new EventHandler(BtnSync_Click);

            btnClose = new Button();
            btnClose.Text = "Fechar";
            btnClose.Size = new Size(100, 34);
            btnClose.Location = new Point(516, 10);
            btnClose.BackColor = Color.FromArgb(226, 232, 240);
            btnClose.ForeColor = Color.FromArgb(51, 65, 85);
            btnClose.FlatStyle = FlatStyle.Flat;
            btnClose.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            btnClose.Click += new EventHandler((s, e) => this.Close());

            bottomPanel.Controls.Add(btnSync);
            bottomPanel.Controls.Add(btnClose);
            this.Controls.Add(bottomPanel);

            this.Shown += new EventHandler(MainForm_Shown);
        }

        private void MainForm_Shown(object sender, EventArgs e)
        {
            StartSyncProcess();
        }

        private void BtnSync_Click(object sender, EventArgs e)
        {
            StartSyncProcess();
        }

        private void Log(string message)
        {
            if (this.InvokeRequired)
            {
                this.Invoke(new Action<string>(Log), message);
                return;
            }
            txtLog.AppendText(string.Format("[{0}] {1}\r\n", DateTime.Now.ToString("HH:mm:ss"), message));
            txtLog.SelectionStart = txtLog.Text.Length;
            txtLog.ScrollToCaret();
        }

        private void SetStatus(string status, Color color)
        {
            if (this.InvokeRequired)
            {
                this.Invoke(new Action<string, Color>(SetStatus), status, color);
                return;
            }
            lblStatus.Text = status;
            lblStatus.ForeColor = color;
        }

        private void SetBusy(bool busy)
        {
            if (this.InvokeRequired)
            {
                this.Invoke(new Action<bool>(SetBusy), busy);
                return;
            }
            progressBar.Visible = busy;
            btnSync.Enabled = !busy;
        }

        private string FindGitExecutable()
        {
            // 1. Caminho local portátil do projeto
            string portable = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), @".gemini\antigravity\scratch\tools\git\cmd\git.exe");
            if (File.Exists(portable)) return portable;

            // 2. Program Files
            string progFiles = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Git\cmd\git.exe");
            if (File.Exists(progFiles)) return progFiles;

            // 3. LocalAppData
            string localApp = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Programs\Git\cmd\git.exe");
            if (File.Exists(localApp)) return localApp;

            // 4. PATH global
            try
            {
                Process p = new Process();
                p.StartInfo.FileName = "where";
                p.StartInfo.Arguments = "git";
                p.StartInfo.UseShellExecute = false;
                p.StartInfo.RedirectStandardOutput = true;
                p.StartInfo.CreateNoWindow = true;
                p.Start();
                string outStr = p.StandardOutput.ReadLine();
                p.WaitForExit();
                if (!string.IsNullOrEmpty(outStr) && File.Exists(outStr.Trim()))
                {
                    return outStr.Trim();
                }
            }
            catch {}

            return null;
        }

        private string RunGit(string arguments, out int exitCode)
        {
            Process p = new Process();
            p.StartInfo.FileName = this.gitPath;
            p.StartInfo.Arguments = arguments;
            p.StartInfo.WorkingDirectory = this.projectDir;
            p.StartInfo.UseShellExecute = false;
            p.StartInfo.RedirectStandardOutput = true;
            p.StartInfo.RedirectStandardError = true;
            p.StartInfo.StandardOutputEncoding = Encoding.UTF8;
            p.StartInfo.StandardErrorEncoding = Encoding.UTF8;
            p.StartInfo.CreateNoWindow = true;

            p.Start();
            string output = p.StandardOutput.ReadToEnd();
            string error = p.StandardError.ReadToEnd();
            p.WaitForExit();
            exitCode = p.ExitCode;

            string full = (output + "\r\n" + error).Trim();
            return full;
        }

        private void StartSyncProcess()
        {
            SetBusy(true);
            SetStatus("Localizando Git...", Color.FromArgb(56, 189, 248));
            txtLog.Clear();
            Log("Iniciando processo de sincronização...");

            System.Threading.ThreadPool.QueueUserWorkItem((state) =>
            {
                try
                {
                    this.gitPath = FindGitExecutable();
                    if (string.IsNullOrEmpty(this.gitPath))
                    {
                        Log("ERRO: Git não encontrado no computador.");
                        SetStatus("Erro: Sem Git", Color.FromArgb(239, 68, 68));
                        SetBusy(false);
                        return;
                    }

                    Log(string.Format("Git detectado: {0}", this.gitPath));

                    int code;
                    // Inicializa se necessário
                    string gitDir = Path.Combine(this.projectDir, ".git");
                    if (!Directory.Exists(gitDir))
                    {
                        Log("Inicializando repositório Git local...");
                        RunGit("init", out code);
                        RunGit("branch -M main", out code);
                    }

                    // Configura usuário se necessário
                    string userCheck = RunGit("config user.name", out code);
                    if (string.IsNullOrEmpty(userCheck))
                    {
                        RunGit("config user.name \"Israel Fernando\"", out code);
                        RunGit("config user.email \"israel.fernando@tvlar.com.br\"", out code);
                    }

                    // Verifica remote 'origin'
                    string remoteUrl = RunGit("remote get-url origin", out code);
                    if (code != 0 || string.IsNullOrEmpty(remoteUrl) || remoteUrl.Contains("fatal:"))
                    {
                        this.Invoke(new Action(() =>
                        {
                            inputPanel.Visible = true;
                            SetStatus("Aguardando URL", Color.FromArgb(245, 158, 11));
                            Log("AVISO: Nenhum repositório GitHub vinculado. Por favor, cole a URL no campo superior.");
                            txtRepoUrl.Focus();
                            SetBusy(false);
                        }));
                        return;
                    }

                    this.Invoke(new Action(() => { inputPanel.Visible = false; }));
                    Log(string.Format("Repositório remoto: {0}", remoteUrl));

                    // Adiciona alterações
                    SetStatus("Coletando arquivos...", Color.FromArgb(56, 189, 248));
                    Log("Adicionando arquivos modificados (git add -A)...");
                    RunGit("add -A", out code);

                    // Commit se houver alterações
                    string status = RunGit("status --porcelain", out code);
                    if (!string.IsNullOrEmpty(status))
                    {
                        string timestamp = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss");
                        Log(string.Format("Gravando commit local: Auto-sync {0}...", timestamp));
                        string commitOut = RunGit(string.Format("commit -m \"Auto-sync: {0}\"", timestamp), out code);
                        Log(commitOut);
                    }
                    else
                    {
                        Log("Nenhuma alteração local pendente de commit.");
                    }

                    // Push
                    SetStatus("Enviando ao GitHub...", Color.FromArgb(168, 85, 247));
                    Log("Enviando atualizações para o GitHub (branch main)...");
                    string pushOut = RunGit("push -u origin main", out code);
                    Log(pushOut);

                    if (code != 0)
                    {
                        Log("Tentando sincronizar com o repositório remoto (git pull --rebase)...");
                        RunGit("pull --rebase origin main", out code);
                        pushOut = RunGit("push -u origin main", out code);
                        Log(pushOut);
                    }

                    if (code == 0)
                    {
                        SetStatus("Sincronizado com Sucesso!", Color.FromArgb(34, 197, 94));
                        Log("=================================================");
                        Log("SUCESSO: Todas as atualizações foram enviadas ao GitHub!");
                        Log("=================================================");
                    }
                    else
                    {
                        SetStatus("Erro no envio", Color.FromArgb(239, 68, 68));
                        Log("ATENÇÃO: Não foi possível enviar ao GitHub.");
                        Log("Dica: Verifique se sua conta do GitHub está autenticada ou se o repositório existe.");
                    }
                }
                catch (Exception ex)
                {
                    Log("Erro inesperado: " + ex.Message);
                    SetStatus("Erro", Color.FromArgb(239, 68, 68));
                }
                finally
                {
                    SetBusy(false);
                }
            });
        }

        private void BtnSaveUrl_Click(object sender, EventArgs e)
        {
            string url = txtRepoUrl.Text.Trim();
            if (string.IsNullOrEmpty(url))
            {
                MessageBox.Show("Por favor, digite ou cole a URL do repositório no GitHub.", "Aviso", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            int code;
            RunGit("remote remove origin", out code);
            string res = RunGit("remote add origin " + url, out code);
            if (code == 0)
            {
                inputPanel.Visible = false;
                Log("Repositório vinculado: " + url);
                StartSyncProcess();
            }
            else
            {
                MessageBox.Show("Erro ao vincular repositório:\n" + res, "Erro", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
