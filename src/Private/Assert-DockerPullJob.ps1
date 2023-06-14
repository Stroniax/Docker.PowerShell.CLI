function Assert-DockerPullJob {
    [CmdletBinding()]
    param()
    process {
        if ('Docker.PowerShell.CLI.DockerPullJob' -as [type]) {
            return
        }

        Add-Type -TypeDefinition @'
using System;
using System.Management.Automation;
using System.Diagnostics;

namespace Docker.PowerShell.CLI {
    public sealed class DockerPullJob : Job
    {
        // Docker process
        private readonly Process _process;
        // Previous line of output. If successfully exiting, this line will
        // contain the image name.
        private string _lastOutput;

        // Abstract member, does not apply
        public override string Location
        {
            get { return _process.MachineName; }
        }

        public override string StatusMessage
        {
            get
            {
                if (_process.HasExited)
                {
                    return string.Format("Exited ({0})", _process.ExitCode);
                }
                else
                {
                    return "Running";
                }
            }
        }

        public override bool HasMoreData
        {
            get
            {
                return Output.Count > 0
                    || Error.Count > 0
                    || Debug.Count > 0;
            }
        }

        public override void StopJob()
        {
            _process.Kill();
            SetJobState(JobState.Stopped);
        }

        public int GetProcessId()
        {
            return _process.Id;
        }

        private static string GetName(string arguments)
        {
            return string.Format("docker {0}", arguments);
        }

        public DockerPullJob(string command, string arguments)
            : base(command, GetName(arguments))
        {
            PSJobTypeName = "DockerJob";
            var startInfo = new ProcessStartInfo("docker", arguments);
            startInfo.RedirectStandardOutput = true;
            startInfo.RedirectStandardError = true;
            startInfo.UseShellExecute = false;
            startInfo.CreateNoWindow = true;

            _process = new Process();
            _process.StartInfo = startInfo;
            _process.EnableRaisingEvents = true;
            _process.Exited += OnProcessExited;
            _process.OutputDataReceived += OnOutputDataReceived;
            _process.ErrorDataReceived += OnErrorDataReceieved;

            SetJobState(JobState.Running);

            _process.Start();
            _process.BeginOutputReadLine();
            _process.BeginErrorReadLine();
        }

        private void OnOutputDataReceived(object sender, DataReceivedEventArgs e)
        {
            if (e == null || e.Data == null)
            {
                return;
            }
            _lastOutput = e.Data;
            var record = new DebugRecord(e.Data);;
            Debug.Add(record);
        }

        private void OnErrorDataReceieved(object sender, DataReceivedEventArgs e)
        {
            if (e == null || e.Data == null)
            {
                return;
            }
            var exn = new Exception(e.Data);
            var err = new ErrorRecord(
                exn,
                "DockerPullError",
                ErrorCategory.FromStdErr,
                null
            );
            Error.Add(err);
        }

        private void OnProcessExited(object sender, EventArgs e)
        {
            if (_process.ExitCode == 0)
            {
                var image = _lastOutput;
                var pso = new PSObject(image);
                Output.Add(pso);

                SetJobState(JobState.Completed);
            }
            else
            {
                SetJobState(JobState.Failed);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _process.Exited -= OnProcessExited;
                _process.OutputDataReceived -= OnOutputDataReceived;
                _process.ErrorDataReceived -= OnErrorDataReceieved;

                _process.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
'@
    }
}
