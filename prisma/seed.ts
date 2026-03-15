import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const roles = [
    { code: "GUEST", name: "Guest" },
    { code: "VENUE_OWNER", name: "Venue Owner" },
    { code: "MARKETING", name: "Marketing" },
    { code: "INFLUENCER", name: "Influencer" },
    { code: "BRAND_ADMIN", name: "Brand Admin" },
    { code: "PLATFORM_ADMIN", name: "Platform Admin" }
  ];

  for (const role of roles) {
    await prisma.role.upsert({
      where: { code: role.code },
      update: { name: role.name },
      create: role
    });
  }
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
