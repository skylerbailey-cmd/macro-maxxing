export function FeatureCard({
  icon,
  title,
  description,
  color = "brand-purple",
}: {
  icon: string;
  title: string;
  description: string;
  color?: string;
}) {
  return (
    <div className="bg-brand-card rounded-2xl p-6 border border-white/5 hover:border-brand-purple/30 transition group">
      <div
        className={`text-3xl mb-4 w-14 h-14 rounded-xl flex items-center justify-center bg-${color}/10`}
      >
        {icon}
      </div>
      <h3 className="text-lg font-semibold text-white mb-2 group-hover:text-brand-purple transition">
        {title}
      </h3>
      <p className="text-gray-400 text-sm leading-relaxed">{description}</p>
    </div>
  );
}
