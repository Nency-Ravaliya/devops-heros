// Visual of the delivery pipeline this app is shipped through (see .github/workflows).
const STAGES = ["Test", "Build", "Scan", "Push", "Deploy"];

export default function PipelineIndicator() {
  return (
    <section className="panel" aria-labelledby="pipeline-heading">
      <h2 id="pipeline-heading">Delivery pipeline</h2>
      <ol className="pipeline">
        {STAGES.map((stage) => (
          <li key={stage} className="pipeline-stage">
            <span className="pipeline-dot" aria-hidden="true">
              ✓
            </span>
            <span>{stage}</span>
          </li>
        ))}
      </ol>
      <p className="muted pipeline-note">
        Every commit runs pytest, builds both images, scans them with Trivy and pushes them to GHCR.
      </p>
    </section>
  );
}
